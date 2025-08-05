/**
Swisser
Copyright (C) 2025 Piero Toffanin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <iostream>
#include <vector>
#include "Tournament.hpp"
#include "Player.hpp"
#include "httplib.h"
#include "json.hpp"
using json = nlohmann::json;
#define APP_VERSION "0.9.1"

int main(int argc, char **argv) {
    httplib::Server svr;
    std::string host = "0.0.0.0";
    int port = 8080;
    bool verbose = false;

    for (int i = 1; i < argc; i++) {
        std::string param = std::string(argv[i]);

        if ((param == "--host" || param == "-h") && i + 1 < argc) {
            host = argv[i + 1];
            i++; 
        } else if ((param == "--port" || param == "-p") && i + 1 < argc) {
            port = std::stoi(argv[i + 1]);
            i++;
        } else if (param == "--verbose" || param == "-v"){
            verbose = true;
            std::cout << "Verbose mode: on" << std::endl;
        }
    }

    svr.Get("/", [](const httplib::Request &, httplib::Response &res) {
        res.set_content("Swisser v" APP_VERSION " is running", "text/plain");
    });
    svr.Get("/ping", [](const httplib::Request &, httplib::Response &res) {
        res.set_content(json( {{"swisser", "running"}, {"version", APP_VERSION }}).dump(), "application/json");
    });
    
    svr.Post("/round", [&verbose](const httplib::Request &req, httplib::Response &res) {
        std::string data = req.get_param_value("data");

        if (verbose){
            std::cout << "POST /round " << data << std::endl;
        }
        
        try{
            json j = json::parse(data);
            int rounds = j.at("rounds").get<int>();

            json games = json::array();
            if (j.contains("games")){
                games = j.at("games");
            }

            CPPDubovSystem::Tournament tournament(rounds);
            std::unordered_map<std::string, CPPDubovSystem::Player> players;
            int id = 1;

            for (const auto &p : j.at("players")){
                std::string name = p.at("name").get<std::string>();
                CPPDubovSystem::Player player(name, 
                                              p.at("elo").get<int>(), id++, 0.0);
                players[name] = player;
            }
            
            int nextRound = games.size() + 1;

            // Replay game history (optional)
            int round_hist = 1;
            for (const auto &results : games){
                for (const auto &r: results){
                    std::string white = r.at("white").get<std::string>();
                    
                    std::string black = "";
                    if (r.contains("black")) black = r["black"].get<std::string>();
                    
                    bool bye = r.contains("bye") && r["bye"].get<bool>();
                    
                    float result = 0.0f;
                    if (r.contains("result")) result = r["result"].get<float>();
                    
                    auto w = &players[white];
                    // White played white
                    if (!bye) w->addColor(CPPDubovSystem::Color::WHITE);

                    // Reset prev upfloat
                    w->setUpfloatPrevStatus(false);

                    if (!black.empty() && !bye){
                        auto b = &players[black];

                        // Black played black
                        b->addColor(CPPDubovSystem::Color::BLACK);

                        // Reset prev upfloat
                        b->setUpfloatPrevStatus(false);

                        // They played each other
                        w->addOpp(b->getID());
                        w->addOppRating(b->getRating());

                        b->addOpp(w->getID());
                        b->addOppRating(w->getRating());
                        
                        // Keep track of upfloaters
                        if (w->getPoints() > b->getPoints()){
                            b->incrementUpfloat();
                            if (round_hist == nextRound - 1) b->setUpfloatPrevStatus(true);
                        }else if (w->getPoints() < b->getPoints()){
                            w->incrementUpfloat();
                            if (round_hist == nextRound - 1) w->setUpfloatPrevStatus(true);
                        }

                        // White won
                        if (result == 1.0){
                            w->addPoints(1.0);
                        // Draw
                        }else if (result == 0.5){
                            w->addPoints(0.5);
                            b->addPoints(0.5);
                        // Black won
                        }else if (result == 0.0){
                            b->addPoints(1.0);
                        }
                        
                    }

                    if (bye){
                        w->addPoints(1.0);
                        w->setByeStatus(true);
                    }
                }

                round_hist++;
            }
            
            for (auto &p : players){
                tournament.addPlayer(p.second);
            }
            std::vector<CPPDubovSystem::Match> pairings = tournament.generatePairings(nextRound);
            
            json pairs = json::array();

            for(int i = 0; i < pairings.size(); i++) {
                CPPDubovSystem::Match match = pairings[i];
                json m = json::object();
                m["white"] = match.white.getName();

                if(match.is_bye) {
                    m["bye"] = true;
                } else {
                    m["black"] = match.black.getName();
                }
                pairs.push_back(m);
            }
            
            std::string out = pairs.dump();
            if (verbose){
                std::cout << "--> " << out << std::endl;
            }
            
            res.set_content(out, "application/json");
        }catch (const std::exception& e) {
            json j;
            j["error"] = e.what();
            std::string out = j.dump();
            if (verbose){
                std::cout << "--> " << out << std::endl;
            }

            res.status = httplib::StatusCode::BadRequest_400;
            res.set_content(out, "application/json");
        }
        
    });

    std::cout << "Running swisser v" APP_VERSION " on " << host << ":" << port << std::endl;
    svr.listen(host, port);
    
    return 0;
}