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

#ifndef RN_DBLRS_H_
#define RN_DBLRS_H_

#include <memory>
#include <vector>
#include <list>
#include <string>
#include "compile_packet.hpp"
#include "switch_modes.hpp"

//#define DEBUG


// Does not support vnsize = 2 and vnsize = 1

namespace MAERI {
  namespace ReductionNetwork {
    class DoubleReductionSwitch {
      protected:

        bool genOutputL_;
        bool genOutputR_;

        DBRS_SubMode modeL_ = DBRS_SubMode::Idle;
        DBRS_SubMode modeR_ = DBRS_SubMode::Idle;

        std::vector<std::shared_ptr<CompilePacket>> input_packets_;
        std::vector<std::shared_ptr<CompilePacket>> output_packets_;

      public:
        int switch_id = 0;

        DoubleReductionSwitch() :
          genOutputL_(false),
          genOutputR_(false),
          modeL_(DBRS_SubMode::Idle),
          modeR_(DBRS_SubMode::Idle)
        {
          for(int injCount = 0; injCount < 4; injCount++) {
            auto invalid_packet = std::make_shared<CompilePacket>();
            input_packets_.push_back(invalid_packet);
          }

          for(int injCount = 0; injCount < 2; injCount++) {
            auto invalid_packet = std::make_shared<CompilePacket>();
            output_packets_.push_back(invalid_packet);
          }
        }

        void PutPacket(std::shared_ptr<CompilePacket> inPacket, int port) {
          if(port < 4) {
            input_packets_[port] = inPacket;
          }
        }

        std::shared_ptr<CompilePacket> GetPacket(int port) {
          if(port < 2) {
            auto ret = output_packets_[port];
            return ret;
          }
          else {
            return nullptr;
          }
        }

        void ProcessPackets() {
          int vn_L = -1;
          int vn_R = -1;

          int vn_L_size = 0;
          int vn_R_size = 0;

          int vn_L_num_packets = 0;
          int vn_R_num_packets = 0;

          int vn_L_num_accumulated_psums = 0;
          int vn_R_num_accumulated_psums = 0;

          if(input_packets_[0]->IsValid()) {
            vn_L = input_packets_[0]->GetVNID();
            vn_L_size = input_packets_[0]->GetVNSize();
          }

          if(input_packets_[3]->IsValid()) {
            vn_R = input_packets_[3]->GetVNID();
            vn_R_size = input_packets_[3]->GetVNSize();
          }

          for(auto inPkt : input_packets_) {
            if(inPkt->IsValid() && inPkt->GetVNID() == vn_L) {
              vn_L_num_accumulated_psums += inPkt->GetNumPSums();
              vn_L_num_packets++;
            }
            else if(inPkt->IsValid() && inPkt->GetVNID() == vn_R) {
              vn_R_num_accumulated_psums += inPkt->GetNumPSums();
              vn_R_num_packets++;
            }
          }
#ifdef DEBUG
          std::cout << "DBRS " << switch_id << ", vn_L =  " << vn_L << ", vn_R = " << vn_R << ", NumLPackets = " << vn_L_num_packets << ", NumRPackets = " << vn_R_num_packets << ", accumulatedL = " << vn_L_num_accumulated_psums << ", accumulatedR = " << vn_R_num_accumulated_psums <<std::endl;
#endif

          //Determine the switch modes
          switch(vn_L_num_packets) {
            case 4:
              modeL_ = DBRS_SubMode::AddTwo;
              break;
            case 3:
              modeL_ = DBRS_SubMode::AddThree;
              break;
            case 2:
              modeL_ = DBRS_SubMode::AddTwo;
              break;
            case 1:
              modeL_ = DBRS_SubMode::AddOne;
              break;
            default:
              modeL_ = DBRS_SubMode::Idle;
          }


          switch(vn_R_num_packets) {
            case 3:
              modeR_ = DBRS_SubMode::AddThree;
              break;
            case 2:
              modeR_ = DBRS_SubMode::AddTwo;
              break;
            case 1:
              modeR_ = DBRS_SubMode::AddOne;
              break;
            case 0:
              if(vn_L_num_packets == 4 && vn_L == vn_R) {
                modeR_ = DBRS_SubMode::AddTwo;
              }
              else {
                modeR_ = DBRS_SubMode::Idle;
              }
              break;
            default:
              modeR_ = DBRS_SubMode::Idle;
          }



          std::string ret = ", ModeL: ";
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

#ifdef DEBUG
          std::cout << "DBRS " << switch_id << " " << ret << std::endl;
#endif

          // Determine output packets and genOutputL
          if(vn_L != -1) {
            if(vn_L_size == vn_L_num_accumulated_psums) {
              genOutputL_ = true;
            }
            else {
              int pSumL = (modeL_ == DBRS_SubMode::AddTwo && modeR_ == DBRS_SubMode::AddTwo)? input_packets_[0]->GetNumPSums() + input_packets_[1]->GetNumPSums() : vn_L_num_accumulated_psums;
              auto outL = std::make_shared<CompilePacket>(vn_L, vn_L_size, pSumL);
#ifdef DEBUG
              std::cout << "DBRS " << switch_id << " Sends out a packet to Port " << 0 << "(L) with vnId:" << vn_L << ", vn_size: " << vn_L_size << ", pSums: " << pSumL << std::endl;
#endif
              output_packets_[0] = outL;
            }
          }

          if(vn_R != -1 || modeR_ == DBRS_SubMode::AddTwo) {
            if(vn_R_size == vn_R_num_accumulated_psums) {
              genOutputR_ = true;
            }
            else {
              int pSumR = (modeL_ == DBRS_SubMode::AddTwo && modeR_ == DBRS_SubMode::AddTwo)? input_packets_[2]->GetNumPSums() + input_packets_[3]->GetNumPSums() : vn_R_num_accumulated_psums;
              auto outR = std::make_shared<CompilePacket>(vn_R, vn_R_size, pSumR);
#ifdef DEBUG
              std::cout << "DBRS " << switch_id << " Sends out a packet to Port " << 1 << "(R) with vnId:" << vn_R << ", vn_size: " << vn_R_size << ", pSums: " << pSumR << std::endl;
#endif
              output_packets_[1] = outR;
            }
          }

          for(auto it : input_packets_) {
            it->Invalidate();
          }

        } // End of void ProcessPackets()

        bool GetGenOutputL() {
          return genOutputL_;
        }

        bool GetGenOutputR() {
          return genOutputR_;
        }

        DBRS_SubMode GetModeL() {
          return modeL_;
        }

        DBRS_SubMode GetModeR() {
          return modeR_;
        }

    };
  };
};

#endif
