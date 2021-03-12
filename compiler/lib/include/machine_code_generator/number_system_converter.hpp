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


#ifndef MG_BIN_TO_HEX_H_
#define MG_BIN_TO_HEX_H_

#include <iostream>
#include <string>
#include <cmath>

namespace MAERI {
  namespace MachineCodeGenerator {

    class BinaryToHex {
      public:
        std::string GetHexString(std::string binaryString) {
          std::string one = "1";
          std::string ret = "";
          if(binaryString.length() != 32) {
            std::cout << "GetHexString: input binary must be 32-bit data" << std::endl;
            return ret;
          }

          int sum = 0;
          for(int digit = 0; digit < 32; digit++) {
            if(binaryString.substr(digit, 1) == one) {
              sum += 8 / pow(2, digit % 4);
            }
            if(digit % 4 == 3) {
              ret += ConvertIntToHex(sum);
              sum = 0;
            }

          }

          return ret;
        }

        std::string ConvertIntToHex(int value) {
          std::string ret = "";
          if(value>15 || value < 0) {
            std::cout << "[ConverIntToHex] out of bound " << value << std::endl;
            return "";
          }
          else {
            switch(value) {
              case 0:
                ret = "0";
                break;
              case 1:
                ret = "1";
                break;
              case 2:
                ret = "2";
                break;
              case 3:
                ret = "3";
                break;
              case 4:
                ret = "4";
                break;
              case 5:
                ret = "5";
                break;
              case 6:
                ret = "6";
                break;
              case 7:
                ret = "7";
                break;
              case 8:
                ret = "8";
                break;
              case 9:
                ret = "9";
                break;
              case 10:
                ret = "A";
                break;
              case 11:
                ret = "B";
                break;
              case 12:
                ret = "C";
                break;
              case 13:
                ret = "D";
                break;
              case 14:
                ret = "E";
                break;
              case 15:
                ret = "F";
                break;
              default:
                ret = "0";
            }
          }

          return ret;
        }

    }; // End of class BinaryToHex

    class IntToHex {
      protected:
        BinaryToHex bin2hex;
      public:
        std::string GetHexString(int targVal, int size) {
          std::string ret = "";

          int remainingVal = targVal;

          while(remainingVal != 0) {
            int hex_digit_val = remainingVal % 16;
            ret.insert(0, bin2hex.ConvertIntToHex(hex_digit_val));
            remainingVal = remainingVal / 16;
          }

          if(ret.length() < size) {
            int num_pad_digit = size - ret.length();

            for(int i=0; i < num_pad_digit; i++) {
              ret.insert(0, "0");
            }
          }

          return ret;
        }


    }; // End of clas IntTOHex




  }; // End of namesapce MachineCodeGenerator
}; // End of namespace MAERI

#endif
