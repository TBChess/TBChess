#include <vector>
#include <map>

#include <tournament/tournament.h>
#include "roundrobin.h"

namespace swisssystems
{
namespace roundrobin
{

std::list<Pairing> computeMatching(tournament::Tournament &&tournament, std::ostream *const){
    std::list<Pairing> games;

    int playerCount = tournament.players.size();
    bool odd = playerCount % 2 != 0;
    int tableIdx = odd ? playerCount + 1 : playerCount;
    int pairingRound = tournament.playedRounds + 1;

    if (playerCount <= 1){
        throw std::runtime_error("Cannot make a round with less than 2 players");
    }

    // Trivial case for two players
    if (playerCount == 2){
        if (pairingRound % 2 == 0){
            games.push_back(Pairing(tournament.players[1].id, tournament.players[0].id));
        }else{
            games.push_back(Pairing(tournament.players[0].id, tournament.players[1].id));
        }
        return games;
    }

    // Build berger table as indicated on https://handbook.fide.com/chapter/C05Annex1

    std::map<int, std::vector< std::vector<std::pair<int, int>>>> tables;
    
    // 2 players
    tables[2] = {
        {{1, 4}, {2, 3}}, // Rd 1
        {{4, 3}, {1, 2}}, // Rd 2
        {{2, 4}, {3, 1}}  // Rd 3
    };
    
    // 3 or 4 players
    tables[4] = {
        {{1, 4}, {2, 3}}, // Rd 1
        {{4, 3}, {1, 2}}, // Rd 2
        {{2, 4}, {3, 1}}  // Rd 3
    };

    // 5 or 6 players
    tables[6] = {
        {{1, 6}, {2, 5}, {3, 4}}, // Rd 1
        {{6, 4}, {5, 3}, {1, 2}}, // Rd 2
        {{2, 6}, {3, 1}, {4, 5}}, // Rd 3
        {{6, 5}, {1, 4}, {2, 3}}, // Rd 4
        {{3, 6}, {4, 2}, {5, 1}}  // Rd 5
    };

    // 7 or 8 players
    tables[8] = {
        {{1, 8}, {2, 7}, {3, 6}, {4, 5}}, // Rd 1
        {{8, 5}, {6, 4}, {7, 3}, {1, 2}}, // Rd 2
        {{2, 8}, {3, 1}, {4, 7}, {5, 6}}, // Rd 3
        {{8, 6}, {7, 5}, {1, 4}, {2, 3}}, // Rd 4
        {{3, 8}, {4, 2}, {5, 1}, {6, 7}}, // Rd 5
        {{8, 7}, {1, 6}, {2, 5}, {3, 4}}, // Rd 6
        {{4, 8}, {5, 3}, {6, 2}, {7, 1}}  // Rd 7
    };

    // 9 or 10 players
    tables[10] = {
        {{1, 10}, {2, 9}, {3, 8}, {4, 7}, {5, 6}}, // Rd 1
        {{10, 6}, {7, 5}, {8, 4}, {9, 3}, {1, 2}}, // Rd 2
        {{2, 10}, {3, 1}, {4, 9}, {5, 8}, {6, 7}}, // Rd 3
        {{10, 7}, {8, 6}, {9, 5}, {1, 4}, {2, 3}}, // Rd 4
        {{3, 10}, {4, 2}, {5, 1}, {6, 9}, {7, 8}}, // Rd 5
        {{10, 8}, {9, 7}, {1, 6}, {2, 5}, {3, 4}}, // Rd 6
        {{4, 10}, {5, 3}, {6, 2}, {7, 1}, {8, 9}}, // Rd 7
        {{10, 9}, {1, 8}, {2, 7}, {3, 6}, {4, 5}}, // Rd 8
        {{5, 10}, {6, 4}, {7, 3}, {8, 2}, {9, 1}}  // Rd 9
    };

    // 11 or 12 players (using 12-player schedule)
    tables[12] = {
        {{1, 12}, {2, 11}, {3, 10}, {4, 9}, {5, 8}, {6, 7}},   // Rd 1
        {{12, 7}, {8, 6}, {9, 5}, {10, 4}, {11, 3}, {1, 2}},   // Rd 2
        {{2, 12}, {3, 1}, {4, 11}, {5, 10}, {6, 9}, {7, 8}},   // Rd 3
        {{12, 8}, {9, 7}, {10, 6}, {11, 5}, {1, 4}, {2, 3}},   // Rd 4
        {{3, 12}, {4, 2}, {5, 1}, {6, 11}, {7, 10}, {8, 9}},   // Rd 5
        {{12, 9}, {10, 8}, {11, 7}, {1, 6}, {2, 5}, {3, 4}},   // Rd 6
        {{4, 12}, {5, 3}, {6, 2}, {7, 1}, {8, 11}, {9, 10}},   // Rd 7
        {{12, 10}, {11, 9}, {1, 8}, {2, 7}, {3, 6}, {4, 5}},   // Rd 8
        {{5, 12}, {6, 4}, {7, 3}, {8, 2}, {9, 1}, {10, 11}},   // Rd 9
        {{12, 11}, {1, 10}, {2, 9}, {3, 8}, {4, 7}, {5, 6}},   // Rd 10
        {{6, 12}, {7, 5}, {8, 4}, {9, 3}, {10, 2}, {11, 1}}    // Rd 11
    };

    // 13 or 14 players (using 14-player schedule)
    tables[14] = {
        {{1, 14}, {2, 13}, {3, 12}, {4, 11}, {5, 10}, {6, 9}, {7, 8}},    // Rd 1
        {{14, 8}, {9, 7}, {10, 6}, {11, 5}, {12, 4}, {13, 3}, {1, 2}},    // Rd 2
        {{2, 14}, {3, 1}, {4, 13}, {5, 12}, {6, 11}, {7, 10}, {8, 9}},    // Rd 3
        {{14, 9}, {10, 8}, {11, 7}, {12, 6}, {13, 5}, {1, 4}, {2, 3}},    // Rd 4
        {{3, 14}, {4, 2}, {5, 1}, {6, 13}, {7, 12}, {8, 11}, {9, 10}},    // Rd 5
        {{14, 10}, {11, 9}, {12, 8}, {13, 7}, {1, 6}, {2, 5}, {3, 4}},    // Rd 6
        {{4, 14}, {5, 3}, {6, 2}, {7, 1}, {8, 13}, {9, 12}, {10, 11}},    // Rd 7
        {{14, 11}, {12, 10}, {13, 9}, {1, 8}, {2, 7}, {3, 6}, {4, 5}},    // Rd 8
        {{5, 14}, {6, 4}, {7, 3}, {8, 2}, {9, 1}, {10, 13}, {11, 12}},    // Rd 9
        {{14, 12}, {13, 11}, {1, 10}, {2, 9}, {3, 8}, {4, 7}, {5, 6}},    // Rd 10
        {{6, 14}, {7, 5}, {8, 4}, {9, 3}, {10, 2}, {11, 1}, {12, 13}},    // Rd 11
        {{14, 13}, {1, 12}, {2, 11}, {3, 10}, {4, 9}, {5, 8}, {6, 7}},    // Rd 12
        {{7, 14}, {8, 6}, {9, 5}, {10, 4}, {11, 3}, {12, 2}, {13, 1}}     // Rd 13
    };

    // 15 or 16 players (using 16-player schedule)
    tables[16] = {
        {{1, 16}, {2, 15}, {3, 14}, {4, 13}, {5, 12}, {6, 11}, {7, 10}, {8, 9}},   // Rd 1
        {{16, 9}, {10, 8}, {11, 7}, {12, 6}, {13, 5}, {14, 4}, {15, 3}, {1, 2}},   // Rd 2
        {{2, 16}, {3, 1}, {4, 15}, {5, 14}, {6, 13}, {7, 12}, {8, 11}, {9, 10}},   // Rd 3
        {{16, 10}, {11, 9}, {12, 8}, {13, 7}, {14, 6}, {15, 5}, {1, 4}, {2, 3}},   // Rd 4
        {{3, 16}, {4, 2}, {5, 1}, {6, 15}, {7, 14}, {8, 13}, {9, 12}, {10, 11}},   // Rd 5
        {{16, 11}, {12, 10}, {13, 9}, {14, 8}, {15, 7}, {1, 6}, {2, 5}, {3, 4}},   // Rd 6
        {{4, 16}, {5, 3}, {6, 2}, {7, 1}, {8, 15}, {9, 14}, {10, 13}, {11, 12}},   // Rd 7
        {{16, 12}, {13, 11}, {14, 10}, {15, 9}, {1, 8}, {2, 7}, {3, 6}, {4, 5}},   // Rd 8
        {{5, 16}, {6, 4}, {7, 3}, {8, 2}, {9, 1}, {10, 15}, {11, 14}, {12, 13}},   // Rd 9
        {{16, 13}, {14, 12}, {15, 11}, {1, 10}, {2, 9}, {3, 8}, {4, 7}, {5, 6}},   // Rd 10
        {{6, 16}, {7, 5}, {8, 4}, {9, 3}, {10, 2}, {11, 1}, {12, 15}, {13, 14}},   // Rd 11
        {{16, 14}, {15, 13}, {1, 12}, {2, 11}, {3, 10}, {4, 9}, {5, 8}, {6, 7}},   // Rd 12
        {{7, 16}, {8, 6}, {9, 5}, {10, 4}, {11, 3}, {12, 2}, {13, 1}, {14, 15}},   // Rd 13
        {{16, 15}, {1, 14}, {2, 13}, {3, 12}, {4, 11}, {5, 10}, {6, 9}, {7, 8}},   // Rd 14
        {{8, 16}, {9, 7}, {10, 6}, {11, 5}, {12, 4}, {13, 3}, {14, 2}, {15, 1}}    // Rd 15
    };

    if (!tables.count(tableIdx)){
        throw std::invalid_argument("No round robin table available");
    }

    auto schedule = tables[tableIdx];
    int cycle = std::floor((pairingRound - 1) / schedule.size());
    bool reverse = cycle % 2 == 1;
    auto round = schedule[(pairingRound - 1) % schedule.size()];

    for (const auto &m : round){
        int whiteId = m.first;
        int blackId = m.second;
        if (reverse){
            std::swap(whiteId, blackId);
        }

        bool bye = false;
        if (odd){
            if (whiteId > playerCount){
                bye = true;
                whiteId = blackId;
            }
            if (blackId > playerCount){
                bye = true;
                blackId = whiteId;
            }
        }

        int wpId = tournament.players[whiteId - 1].id;
        int bpId = tournament.players[blackId - 1].id;
        if (bye) bpId = wpId;

        games.push_back(Pairing(wpId, bpId));
    }

    return games;

}

}
}
