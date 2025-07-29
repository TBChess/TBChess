//
//  rtg.hpp
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

#ifndef rtg_hpp
#define rtg_hpp

#include <stdio.h>
#include <string>
#include <vector>

/**
 * FIDE requires this for checking. We can make random tournaments with this
 */
namespace RandomTournamentGenerator {
/**
 * A random player to output to the trf
 */
class RawPlayer {
private:
    /**
     * Standard name
     */
    std::string raw_name;
    /**
     * Standard rating
     */
    int raw_rating;
    /**
     * Match output
     */
    std::vector<std::string> raw_games;
    /**
     * Standard points
     */
    double raw_points;
    /**
     * Standard rank
     */
    int raw_rank;
    /**
     * Standard final rank
     */
    int raw_final_rank = 0;
public:
    /**
     * Initializes the raw player with a given name, rating, and rank (pairing number)
     */
    RawPlayer(std::string raw_name, int raw_rating, int rank);
    /**
     * Just empty default constructor
     */
    RawPlayer();
    
    /**
     * Gets the player representation of the trf data
     */
    std::string getTRFLiteral() const;
    
    /**
     * Adds a game played
     */
    void appendRawGame(std::string raw_game);
    /**
     * Increments raw points by a specific amount
     */
    void incrementRawPoints(double pts);
    /**
     * Sets the final rank of the player
     */
    void setFinalRank(int fr) {raw_final_rank = fr;}
};
/**
 * Generates a random tournament and returns the trf string interpretation of it
 */
std::string trfString(int player_count, int rounds, const std::vector<RandomTournamentGenerator::RawPlayer> &players);
}

#endif /* rtg_hpp */
