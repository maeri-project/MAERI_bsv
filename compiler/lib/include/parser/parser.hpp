/******************************************************************************
Copyright (c) 2019 Georgia Instititue of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Author: Hyoukjun Kwon (hyoukjun@gatech.edu)

*******************************************************************************/

#ifndef MAESTRO_PRAGMA_PARSER_HPP_
#define MAESTRO_PRAGMA_PARSER_HPP_

#include <string>
#include <iostream>
#include <fstream>
#include <cstdlib>

#include<boost/tokenizer.hpp>
#include<boost/format.hpp>

#include "analysis-structure.hpp"

namespace maestro {

  class InputParser {
    protected:
      std::string file_name_;
      std::ifstream in_file_;

    public:
      InputParser(std::string file_nm) :
        file_name_(file_nm)
      {
        in_file_.open(file_nm);
        if(!in_file_) {
          std::cout << "Failed to open the input file" << std::endl;
        }
      }
  }; // End of class InputParser


  class LayerParser : public InputParser {
    protected:

    public:
      LayerParser(std::string file_nm) :
        InputParser(file_nm)
      {
      }

      std::shared_ptr<LoopInfoTable> ParseLayer() {
        auto prob_table = std::make_shared<LoopInfoTable>();
        std::string line;

        //Read a line of the file
        while(std::getline(in_file_, line)) {
          boost::char_separator<char> sep(" ,->()");
          boost::tokenizer<boost::char_separator<char>> tokn(line, sep);

          std::string loop_var;

          bool saw_var = false;
          bool saw_size = false;
          bool saw_tile = false;
          int size = 0;
          int tileSz = 0;

          for(auto& tok : tokn) {
            if(!saw_var) {
              loop_var = tok;
              saw_var = true;
            }
            else if (!saw_size){
              size = std::atoi(tok.c_str());
              saw_size = true;
            }
            else if(!saw_tile) {
              tileSz = std::atoi(tok.c_str());
              saw_tile = true;
            }
            else {
              //TODO: Update error message with a better version
              std::cout << "[ProblemParser]Warning: Located extra arguments in problem dimension description. Ignoring extra arguments " << std::endl;
            }
          }

          auto loop_info = std::make_shared<LoopInformation>(loop_var, 0, size, tileSz);
          prob_table->AddLoop(loop_info);

        }
        return prob_table;
      }

  }; // End of class ProblemParser



}; // End of namespace maestro

#endif
