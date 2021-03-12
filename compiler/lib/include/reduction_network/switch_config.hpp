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

#ifndef RN_SWITCH_CONFIG_H_
#define RN_SWITCH_CONFIG_H_

#include <string>

#include "switch_modes.hpp"

namespace MAERI {
  namespace ReductionNetwork {
    class DBRS_Config {
      public:
        bool genOutputL_;
        bool genOutputR_;

        DBRS_SubMode modeL_;
        DBRS_SubMode modeR_;

        std::string ToString() {
          std::string ret = "";

          ret += "GenOutputL: ";

          if(genOutputL_) {
            ret += "True";
          }
          else {
            ret += "False";
          }

          ret += ", GenOutputR: ";
          if(genOutputR_) {
            ret += "True";
          }
          else {
            ret += "False";
          }

          ret += ", ModeL: ";
          if (modeL_ == DBRS_SubMode::AddOne) {
            ret += "AddOne";
          }
          else if (modeL_ == DBRS_SubMode::AddTwo) {
            ret += "AddTwo";
          }
          else if (modeL_ == DBRS_SubMode::AddThree) {
            ret += "AddThree";
          }
          else {
            ret += "Idle";
          }


          ret += ", ModeR: ";
          if (modeR_ == DBRS_SubMode::AddOne) {
            ret += "AddOne";
          }
          else if (modeR_ == DBRS_SubMode::AddTwo) {
            ret += "AddTwo";
          }
          else if (modeR_ == DBRS_SubMode::AddThree) {
            ret += "AddThree";
          }
          else {
            ret += "Idle";
          }

          return ret;
        }
    };

    class SGRS_Config {
      public:
        bool genOutput_;

        SGRS_Mode mode_;

        std::string ToString() {

          std::string ret = "";

           ret += "GenOutput: ";

           if(genOutput_) {
             ret += "True";
           }
           else {
             ret += "False";
           }

           ret += ", Mode: ";
           if (mode_ == SGRS_Mode::AddTwo) {
             ret += "AddTwo";
           }
           else if (mode_ == SGRS_Mode::FlowLeft) {
             ret += "FlowLeft";
           }
           else if (mode_ == SGRS_Mode::FlowRight) {
             ret += "FlowRight";
           }
           else {
             ret += "Idle";
           }

           return ret;
        }
    };
  };
};

#endif
