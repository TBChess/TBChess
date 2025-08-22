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
#include <tournament/tournament.h>
#include <swisssystems/dutch.h>
#include <swisssystems/common.h>

#include "httplib.h"
#include "json.hpp"
#include "validate.hpp"

using json = nlohmann::json;
#define APP_VERSION "0.9.5"


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
            json games = json::array();
            if (j.contains("games")){
                games = j.at("games");
            }
            std::string format = "auto";
            if (j.contains("format")){
                format = j.at("format").get<std::string>();
                if (format != "auto" && format != "swiss" && format != "roundrobin"){
                    format = "auto";
                }
            }

            tournament::Tournament tournament;
            tournament.expectedRounds = j.at("rounds").get<int>();
            tournament.playedRounds = games.size();
            tournament.initialColor = tournament::COLOR_WHITE;
            
            std::vector<std::string> sortedPlayerNames;
            std::unordered_map<std::string, tournament::Player> players;
            std::unordered_map<tournament::player_index, std::string> playerNames;
            
            tournament::player_index id = 0;

            for (const auto &p : j.at("players")){
                std::string name = p.at("name").get<std::string>();
                tournament::rating rating = p.at("elo").get<int>();
                
                tournament::Player player(id, 0.0, rating);
                playerNames[id] = name;
                id++;

                players[name] = player;
                sortedPlayerNames.push_back(name);
            }

            // Replay game history (optional)
            for (const auto &results : games){
                // Account for all players 
                std::unordered_map<std::string, bool> seen; 

                for (const auto &r: results){
                    std::string white = r.at("white").get<std::string>();
                    seen[white] = true;
                    
                    std::string black = "";
                    if (r.contains("black")){
                        black = r["black"].get<std::string>();
                        seen[black] = true;
                    }
                    
                    bool bye = r.contains("bye") && r["bye"].get<bool>();
                    
                    float result = 0.0f;
                    if (r.contains("result")) result = r["result"].get<float>();
                    
                    auto w = &players[white];
                    auto wm = &w->matches;

                    if (!black.empty() && !bye){
                        auto b = &players[black];

                        auto bm = &b->matches;

                        tournament::MatchScore ws;
                        tournament::MatchScore bs;

                        // White won
                        if (result == 1.0f){
                            ws = tournament::MATCH_SCORE_WIN;
                            bs = tournament::MATCH_SCORE_LOSS;
                            w->scoreWithoutAcceleration += tournament.pointsForWin;
                            b->scoreWithoutAcceleration += tournament.pointsForLoss;
                            
                        // Draw
                        }else if (result == 0.5f){
                            ws = tournament::MATCH_SCORE_DRAW;
                            bs = tournament::MATCH_SCORE_DRAW;
                            w->scoreWithoutAcceleration += tournament.pointsForDraw;
                            b->scoreWithoutAcceleration += tournament.pointsForDraw;
                            
                        // Black won
                        }else if (result == 0.0f){
                            ws = tournament::MATCH_SCORE_LOSS;
                            bs = tournament::MATCH_SCORE_WIN;
                            w->scoreWithoutAcceleration += tournament.pointsForLoss;
                            b->scoreWithoutAcceleration += tournament.pointsForWin;
                        }else{
                            throw std::runtime_error("Invalid game result (not 0, 0.5 or 1)");
                        }

                        wm->emplace_back(b->id,
                            tournament::COLOR_WHITE,
                            ws,
                            true,
                            true);
                        bm->emplace_back(w->id,
                            tournament::COLOR_BLACK,
                            bs,
                            true,
                            true);
                    }else if (bye){
                        tournament::MatchScore ms;
                        if (result == 0.0f) ms = tournament::MATCH_SCORE_LOSS;
                        else if (result == 0.5f) ms = tournament::MATCH_SCORE_DRAW;
                        else if (result == 1.0f) ms = tournament::MATCH_SCORE_WIN;
                        else throw std::runtime_error("Invalid game result (not 0, 0.5 or 1)");

                        wm->emplace_back(w->id,
                            tournament::COLOR_NONE,
                            ms,
                            false,
                            false);
                        
                        if (result == 1.0f) w->scoreWithoutAcceleration += tournament.pointsForPairingAllocatedBye;
                        else if (result == 0.5f) w->scoreWithoutAcceleration += tournament.pointsForDraw;
                        else if (result == 0.0f) w->scoreWithoutAcceleration += tournament.pointsForLoss;
                    }
                }
                

                // Check for players that might have skipped a round
                if (seen.size() < players.size()){
                    for (const auto& p : players) {
                        const std::string& playerId = p.first;
                        if (seen.find(playerId) == seen.end()) {
                            // Add 0 point bye
                            auto w = &players[playerId];
                            auto wm = &w->matches;

                            wm->emplace_back(w->id,
                                tournament::COLOR_NONE,
                                tournament::MATCH_SCORE_LOSS,
                                false,
                                false);
                            w->scoreWithoutAcceleration += tournament.pointsForLoss;
                        }
                    }
                }
            }
            
            for (auto &name : sortedPlayerNames){
                auto p = players[name];
                tournament.playersByRank.push_back(p.id);
                tournament.players.push_back(std::move(p));
            }

            int numPlayers = tournament.players.size();
            int numRounds = tournament.expectedRounds;

            if (numPlayers <= 1 || numRounds <= 0){
                throw std::runtime_error("Cannot pair single or no players or when num rounds <= 0");
            }

            swisssystems::SwissSystem swissSystem;

            if (format == "auto"){
                // minSwissPlayers[3] -> minimum number of players for a 3 rounds swiss tournament to work 
                // determined empirically by stress testing the system
                int minSwissPlayers[9] = {
                    -1, -1, 
                    3, // 2 rounds
                    3, // 3 rounds
                    5, // 4 rounds
                    7, // 5 rounds
                    9, // 6 rounds
                    9, // 7 rounds
                    11, // 8 rounds
                };
                int safeNumberOfSwissRounds = static_cast<int>(std::log2(numPlayers) + 1);
    
                if ((numPlayers > 16) ||  // Round robin limit
                    (numRounds == 1) || // Trivial case
                    (numRounds <= safeNumberOfSwissRounds) || // Safe
                    (numRounds <= 8 && minSwissPlayers[numRounds] <= numPlayers)){ // Tested empirically 
                    swissSystem = swisssystems::DUTCH;
                }else{
                    swissSystem = swisssystems::ROUNDROBIN;
                }
            }else if (format == "roundrobin"){
                swissSystem = swisssystems::ROUNDROBIN;
            }else if (format == "swiss"){
                swissSystem = swisssystems::DUTCH;
            }else{
                throw std::runtime_error("Invalid format");
            }

            const swisssystems::Info &info = swisssystems::getInfo(swissSystem);
            
            validatePairConsistency(tournament);
            validateScores(tournament);

            tournament.updateRanks();
            tournament.computePlayerData();
            info.updateAccelerations(tournament, tournament.playedRounds);
            std::list<swisssystems::Pairing> roundPairs = info.computeMatching(std::move(tournament), nullptr);
            swisssystems::sortResults(roundPairs, tournament);
            
            json pairs = json::array();
            for (const swisssystems::Pairing &p : roundPairs){
                json m = json::object();
                m["white"] = playerNames[p.white];

                if (p.white == p.black){
                    m["bye"] = true;
                }else{
                    m["black"] = playerNames[p.black];
                }

                pairs.push_back(m);
            }

            std::string out = pairs.dump();
            if (verbose){
                std::cout << "--> " << out << std::endl;
            }
            
            res.set_content(out, "application/json");
        }catch (const swisssystems::NoValidPairingException &e){
            json j = json::array();
            std::string out = j.dump();
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
