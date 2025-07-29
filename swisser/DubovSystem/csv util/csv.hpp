//
//  csv.hpp
//  DubovSystem
//
//  Created by Michael Shapiro on 7/23/24.
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

#ifndef csv_hpp
#define csv_hpp

#include <stdio.h>
#include <string>
#include <vector>

// for writing data to an output file

/**
 * The pairing table to output
 */
class PairingTable {
private:
    /**
     * The rows to output
     */
    std::vector<std::string> rows;
public:
    /**
     * Just a default constructor
     */
    PairingTable() = default;
    /**
     * Copy not allowed
     */
    PairingTable(const PairingTable &pt) = delete;
    /**
     * Move not allowed
     */
    PairingTable(PairingTable &&pt) = delete;
    /**
     * Assignment not allowed
     */
    PairingTable &operator=(const PairingTable &pt) = delete;
    /**
     * Move assignment not allowed
     */
    PairingTable &operator=(PairingTable &&pt) = delete;
    
    /**
     * Adds a row to the csv table
     */
    void addRow(std::string w, std::string b);
    /**
     * Outputs the pairing table to a file
     */
    void outputToFile(std::string path);
};

#endif /* csv_hpp */
