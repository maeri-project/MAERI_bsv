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

#ifndef RN_SGLRS_H_
#define RN_SGLRS_H_

#include <iostream>
#include <memory>
#include <vector>
#include <list>
#include "compile_packet.hpp"
#include "switch_modes.hpp"

//#define DEBUG


namespace MAERI {
  namespace ReductionNetwork {
    class SingleReductionSwitch {
      protected:
        bool genOutput_;

        SGRS_Mode mode_ = SGRS_Mode::Idle;

        std::vector<std::shared_ptr<CompilePacket>> input_packets_;
        std::vector<std::shared_ptr<CompilePacket>> output_packets_;

      public:
        int switch_id = 0;

        SingleReductionSwitch() :
          genOutput_(false),
          mode_(SGRS_Mode::Idle)
        {
          for(int injCount = 0; injCount < 2; injCount++) {
            auto invalid_packet = std::make_shared<CompilePacket>();
            input_packets_.push_back(invalid_packet);
          }

          for(int injCount = 0; injCount < 1; injCount++) {
            auto invalid_packet = std::make_shared<CompilePacket>();
            output_packets_.push_back(invalid_packet);
          }
        }

        void PutPacket(std::shared_ptr<CompilePacket> inPacket, int port) {
          if(port < 2) {
            input_packets_[port] = inPacket;
          }
        }

        std::shared_ptr<CompilePacket> GetPacket(int port) {
          if(port == 0) {
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

          if(input_packets_[1]->IsValid()) {
            vn_R = input_packets_[1]->GetVNID();
            vn_R_size = input_packets_[1]->GetVNSize();
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
          std::cout << "SGRS " << switch_id << ", vn_L =  " << vn_L << ", vn_R = " << vn_R << ", NumLPackets = " << vn_L_num_packets << ", NumRPackets = " << vn_R_num_packets << ", accumulatedL = " << vn_L_num_accumulated_psums << ", accumulatedR = " << vn_R_num_accumulated_psums <<std::endl;
#endif


          if(vn_L != -1 && vn_R != -1 && vn_L == vn_R) {
          std::cout << "Num Accum PSumsL: " << vn_L_num_accumulated_psums << std::endl;
          std::cout << "Num Accum PSumsR: " << vn_R_num_accumulated_psums << std::endl;
            
            mode_ = SGRS_Mode::AddTwo;
            if(vn_L_size == vn_L_num_accumulated_psums) {
              genOutput_ = true;
            }
            else {
#ifdef DEBUG
              std::cout << "SGRS " << switch_id << " Sends out a packet with vnID: " << vn_L << ", vn_size: " << vn_L_size << ", pSums: " << vn_L_num_accumulated_psums << std::endl;
#endif
              output_packets_[0] = std::make_shared<CompilePacket>(vn_L, vn_L_size, vn_L_num_accumulated_psums);
            }
          }
          else if(vn_L == -1 && vn_R != -1) {
            mode_ = SGRS_Mode::FlowRight;
#ifdef DEBUG
            std::cout << "SGRS " << switch_id << " Sends out a packet with vnID: " << vn_R << ", vn_size: " << vn_R_size << ", pSums: " << vn_R_num_accumulated_psums << std::endl;
#endif
            output_packets_[0] = std::make_shared<CompilePacket>(vn_R, vn_R_size, vn_R_num_accumulated_psums);
          }
          else if(vn_L != -1 && vn_R == -1) {
            mode_ = SGRS_Mode::FlowLeft;
#ifdef DEBUG
            std::cout << "SGRS " << switch_id << " Sends out a packet with vnID: " << vn_L << ", vn_size: " << vn_L_size << ", pSums: " << vn_L_num_accumulated_psums << std::endl;
#endif
            output_packets_[0] = std::make_shared<CompilePacket>(vn_L, vn_L_size, vn_L_num_accumulated_psums);
          }
          else {
            mode_ = SGRS_Mode::Idle;
          }

          for(auto it : input_packets_) {
            it->Invalidate();
          }

        } // End of void ProcessPackets()

        bool GetGenOutput() {
          return genOutput_;
        }

        SGRS_Mode GetMode() {
          return mode_;
        }

    };
  }; // End of namespace ReductionNetwork
}; // End of namespace MAERI

#endif
