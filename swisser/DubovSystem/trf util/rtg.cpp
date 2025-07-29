//
//  rtg.cpp
//  DubovSystem
//
//  Created by Michael Shapiro on 5/22/24.
//

// Copyright 2024 Michael Shapiro
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "rtg.hpp"
#include <cstdlib>

RandomTournamentGenerator::RawPlayer::RawPlayer(std::string raw_name, int raw_rating, int rank) {
    this->raw_name = raw_name;
    this->raw_rating = raw_rating;
    this->raw_rank = rank;
    this->raw_points = 0.0;
}

RandomTournamentGenerator::RawPlayer::RawPlayer() {
    this->raw_name = "";
    this->raw_rating = 0;
    this->raw_rank = -1;
    this->raw_points = 0.0;
}

void RandomTournamentGenerator::RawPlayer::incrementRawPoints(double pts) {
    this->raw_points += pts;
}

void RandomTournamentGenerator::RawPlayer::appendRawGame(std::string raw_game) {
    this->raw_games.push_back(raw_game);
}

std::string RandomTournamentGenerator::RawPlayer::getTRFLiteral() const {
    std::string trf_literal = "001 ";
    
    //rank
    std::string r = std::to_string(this->raw_rank);
    
    while(r.length() < 4) {
        r = " " + r;
    }
    
    trf_literal += r + "      ";
    
    // name
    std::string n = this->raw_name;
    while(n.length() <= 32) {
        n += " ";
    }
    
    trf_literal += n;
    
    // rating
    std::string rr = std::to_string(this->raw_rating);
    while(rr.length() < 4) {
        rr = " " + rr;
    }
    
    trf_literal += " " + rr;
    
    // country
    trf_literal += " USA ----------- 0000/00/00 ";
    // points
    std::string pt = std::to_string(this->raw_points);
    if(pt.length() > 2) {
        pt = pt.substr(0, 3);
    }
    while(pt.length() < 4) {
        pt = " " + pt;
    }
    trf_literal += pt;
    
    // final rank
    std::string frr = std::to_string(this->raw_final_rank);
    while(frr.length() < 4) {
        frr = " " + frr;
    }
    trf_literal += " " + frr;
    
    // games
    for(int i = 0; i < this->raw_games.size(); i++) {
        std::string g = this->raw_games[i];
        while(g.length() < 8) {
            g = " " + g;
        }
//        trf_literal += "  " + this->raw_games[i];
        trf_literal += "  " + g;
    }
    
    return trf_literal;
}

std::string RandomTournamentGenerator::trfString(int player_count, int rounds, const std::vector<RandomTournamentGenerator::RawPlayer> &players) {
    std::string trf_str = "";
    
    // set up basic info
    trf_str = "012 CPP DUBOV SYSTEM RANDOM TOURNAMENT\r\n022 --CPP DUBOV SYSTEM RANDOM TOURNAMENT (CITY)--\r\n032 --CPP DUBOV SYSTEM RANDOM TOURNAMENT (FEDERATION)--\r\n042 --CPP DUBOV SYSTEM RANDOM TOURNAMENT (START DATE)--\r\n052 --CPP DUBOV SYSTEM RANDOM TOURNAMENT (END DATE)--\r\n062 " + std::to_string(player_count) + "\r\n072 " + std::to_string(player_count) + "\r\n082 0\r\n092 Individual FIDE Dubov\r\n102 --CPP DUBOV SYSTEM RANDOM TOURNAMENT; ARBITER (12345678)--\r\n112 \r\n122 MOVES/TIME INCREMENT\r";
    
    // check if we should add rounds
    if(rounds > 0) {
        // we can add rounds
        trf_str += "\nTNR " + std::to_string(rounds) + "\r";
    }
    
    // add players
    for(int i = 0; i < players.size(); i++) {
        trf_str += "\n" + players[i].getTRFLiteral() + "\r";
    }
    
    return trf_str;
}
