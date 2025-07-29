//
//  fpc.cpp
//  DubovSystem
//
//  Created by Michael Shapiro on 5/23/24.
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

#include "fpc.hpp"
#include "assertm.h"
#include <map>
#include <set>

fpc::PairingsChecker::PairingsChecker(const std::string &rawTournament, int targetRound) {
    this->rawTournamentData = rawTournament;
    this->target_round = targetRound;
    if(targetRound < 0) {
        throw std::invalid_argument("Target round cannot be negative!");
    }
}

void fpc::PairingsChecker::scan() {
    // rebuild tournament
    TRFUtil::TRFFile trf_read(this->rawTournamentData);
    TRFUtil::TRFData raw_data = trf_read.read();
    
    // make sure tnr code was present in file
    if(!raw_data.tnrCodeExists()) {
        throw std::runtime_error("Missing tournament number of rounds in TRF file");
    }
    
    int next_round = 0; // dummy variable
    CPPDubovSystem::Tournament rawTournament = CPPDubovSystem::Tournament::makeTournament(raw_data, &next_round, this->target_round);
    
    // make sure targetRound is valid
    std::vector<CPPDubovSystem::Utils::TRFMatch> raw_matches = rawTournament.getRawMatches();
    this->match_check = raw_matches;
    if(((int) raw_matches.size()) == 0) {
        throw std::length_error("Pairings Checker cannot check pairings because invalid round was given to check. Tournament has not reached round " + std::to_string(this->target_round) + " yet.");
    }
    
    // set up player map for comparisons
    std::map<int, CPPDubovSystem::Player> comp;
    for(int i = 0; i < rawTournament.getPlayerCount(); i++) {
        comp[rawTournament.getPlayers()[i].getID()] = rawTournament.getPlayers()[i];
    }
    
    // quickly scan current pairings for comparison
    
    for(int i = 0; i < raw_matches.size(); i++) {
        // check if both players have played each other before
        if(!comp[raw_matches[i].getWID()].canPlayOpp(comp[raw_matches[i].getBID()])) {
            bad_opp += 1;
            continue;
        }
        
        // check due colors
        CPPDubovSystem::Color wd = comp[raw_matches[i].getWID()].getDueColor();
        CPPDubovSystem::Color bd = comp[raw_matches[i].getBID()].getDueColor();
        
        if(wd == bd) {
            // check strengths
            CPPDubovSystem::ColorPreference wp = comp[raw_matches[i].getWID()].getPreferenceStrength();
            CPPDubovSystem::ColorPreference bp = comp[raw_matches[i].getBID()].getPreferenceStrength();
            
            if(wp == CPPDubovSystem::ColorPreference::ABSOLUTE && bp == CPPDubovSystem::ColorPreference::ABSOLUTE) {
                bad_color += 1;
                continue;
            }
        }
    }
    
    // make pairings for expected
    this->games_expected = rawTournament.generatePairings(this->target_round, raw_data.isAccelerationOn());
    this->players_scaned = comp;
    
    // validate pairing count
    int expected_count = rawTournament.getPlayerCount();
    if(expected_count % 2 > 0) {
        expected_count -= 1;
        expected_count = expected_count / 2;
        expected_count += 1;
    } else {
        expected_count = expected_count / 2;
    }
    
    ASSERT(((int) this->games_expected.size()) == expected_count, "expected " + std::to_string(expected_count) + " games but got " + std::to_string(this->games_expected.size()) + " number of games");
    
    // also scan which games were not present in the ones to check
    std::set<std::string> found;
    for(int i = 0; i < raw_matches.size(); i++) {
        std::string raw_hash = std::to_string(raw_matches[i].getWID());
        if(raw_matches[i].is_bye) {
            raw_hash += "_bye";
        } else {
            raw_hash += "_" + std::to_string(raw_matches[i].getBID());
        }
        found.insert(raw_hash);
    }
    for(int i = 0; i < this->games_expected.size(); i++) {
        std::string raw_hash = std::to_string(this->games_expected[i].white.getID()) + "_";
        if(this->games_expected[i].is_bye) {
            raw_hash += "bye";
        } else {
            raw_hash += std::to_string(this->games_expected[i].black.getID());
        }
        if(!found.contains(raw_hash)) {
            this->games_no_found.push_back(this->games_expected[i]);
        }
    }
}

std::string fpc::PairingsChecker::outputReport() {
    std::string output = "----------CPP FIDE DUBOV SYSTEM PAIRINGS CHECKER REPORT----------\n";
    output += "----------CHECKING FOR ROUND: " + std::to_string(this->target_round) + "--------\n";
    output += "----------RUNNING SCANS--------------------------\n";
    
    this->scan();
    
    output += "CHECKER PAIRINGS (EXPECTED):\n\n";
    for(int i = 0; i < this->games_expected.size(); i++) {
        std::string wp = "(" + std::to_string(this->games_expected[i].white.getPoints()) + ")";
        std::string bp = "(" + std::to_string(this->games_expected[i].black.getPoints()) + ")";
        output += this->games_expected[i].white.getName() + wp + " - ";
        if(this->games_expected[i].is_bye) {
            output += "BYE\n";
        } else {
            output += this->games_expected[i].black.getName() + bp + "\n";
        }
    }
    output += "\nTOURNAMENT PAIRINGS (TO CHECK):\n\n";
    for(int i = 0; i < this->match_check.size(); i++) {
        std::string wp = "(" + std::to_string(this->players_scaned[this->match_check[i].getWID()].getPoints()) + ")";
        std::string bp = "(" + std::to_string(this->players_scaned[this->match_check[i].getBID()].getPoints()) + ")";
        output += this->players_scaned[this->match_check[i].getWID()].getName() + wp + " - ";
        //TODO: BYE CHECK
        output += this->players_scaned[this->match_check[i].getBID()].getName() + bp + "\n";
    }
    
    output += "\nERRORS TOTAL DETECTED IN TOURNAMENT PAIRINGS: " + std::to_string(this->bad_opp + this->bad_color);
    output += "\nNUMBER OF PAIRINGS THAT VIOLATE C1 (TWO PLAYERS SHALL NOT MEET TWICE): " + std::to_string(this->bad_opp);
    output += "\nNUMBER OF PAIRINGS THAT VIOLATE C3 (COLOR PREF.): " + std::to_string(this->bad_color);
    
    // output any pairings not found
    output += "\nEXPECTED GAMES NOT FOUND IN PAIRINGS CHECKED:\n";
    for(int i = 0; i < this->games_no_found.size(); i++) {
        output += "\n" + this->games_no_found[i].white.getName() + " (" + std::to_string(this->games_no_found[i].white.getPoints()) + ")";
        if(this->games_no_found[i].is_bye) {
            output += " - BYE";
        } else {
            output += " - " + this->games_no_found[i].black.getName() + " (" + std::to_string(this->games_no_found[i].black.getPoints()) + ")";
        }
    }
    
    int ge = (int) this->games_expected.size();
    
    output += "\n\nTOTAL GAMES NOT_MATCHED/TOTAL: " + std::to_string((int) this->games_no_found.size()) + "/" + std::to_string(ge);
    
    output += "\n\nPAIRINGS CHECKER REPORT DONE\n";
    
    return output;
}
