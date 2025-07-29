//
//  csv.cpp
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

#include "csv.hpp"
#include <fstream>

void PairingTable::addRow(std::string w, std::string b) {
    // add both pieces of data to row and nullptr
    this->rows.push_back(w);
    this->rows.push_back(b);
}

void PairingTable::outputToFile(std::string path) {
    // is is known that rows should have an even number of elements
    std::ofstream output_file(path);
    
    std::string full_output = "White,Black";
    for(int i = 0; i < this->rows.size(); i += 2) {
        full_output += "\n" + this->rows[i] + "," + this->rows[i + 1];
    }
    
    output_file << full_output;
    
    output_file.close();
}
