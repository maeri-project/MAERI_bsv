/******************************************************************************
Copyright (c) 2019 Georgia Instititue of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Author: Hyoukjun Kwon (hyoukjun@gatech.edu)

*******************************************************************************/

#ifndef RN_ABSTRACT_REDUCTION_NETWORK_H_
#define RN_ABSTRACT_REDUCTION_NETWORK_H_

#include <iostream>
#include <vector>
#include <memory>
#include <cmath>
#include <cassert>

#include "switch_modes.hpp"
#include "switch_config.hpp"
#include "single_reduction_switch.hpp"
#include "double_reduction_switch.hpp"

//#define DEBUG


namespace MAERI {
  namespace ReductionNetwork {
    class AbstractReductionNetwork {
      protected:
        int num_mult_switches_;
        int num_levels_;
        int vn_size_;

        std::vector<std::vector<std::shared_ptr<SingleReductionSwitch>>> single_reduction_switches_;
        std::vector<std::vector<std::shared_ptr<DoubleReductionSwitch>>> double_reduction_switches_;

      public:
        AbstractReductionNetwork(int numMultSwitches, int vn_size) :
          num_mult_switches_(numMultSwitches),
          vn_size_(vn_size)  {

          int numLvs = static_cast<int>(log2(numMultSwitches));

          num_levels_ = numLvs;

          for(int lv = 0; lv < numLvs ; lv++) {
            std::vector<std::shared_ptr<SingleReductionSwitch>> lvSgrs;
            single_reduction_switches_.push_back(lvSgrs);

            std::vector<std::shared_ptr<DoubleReductionSwitch>> lvdbrs;
            double_reduction_switches_.push_back(lvdbrs);
          }

          int sgrs_swid = 0;
          int dbrs_swid = 0;
          for(int lv = 0; lv < numLvs ; lv++) {
            int num_sgrs_in_lv = (lv == 0)? 1 : 2;
            for(int sw = 0; sw < num_sgrs_in_lv; sw++) {
              auto new_sgrs = std::make_shared<SingleReductionSwitch>();
              new_sgrs->switch_id = sgrs_swid;
              single_reduction_switches_[lv].push_back(new_sgrs);
#ifdef DEBUG
              std::cout << "SGRS[" << lv << "][" << sw << "] is being initialized" << std::endl;
#endif
              sgrs_swid++;
            }

            int num_dbrs_in_lv = GetNumDBRS(lv);
            if(num_dbrs_in_lv > 0) {
              for(int sw = 0; sw < num_dbrs_in_lv; sw++) {
                auto new_dbrs = std::make_shared<DoubleReductionSwitch>();
                new_dbrs->switch_id = dbrs_swid;
                double_reduction_switches_[lv].push_back(new_dbrs);
#ifdef DEBUG
                std::cout << "DBRS[" << lv << "][" << sw << "] is being initialized" << std::endl;
#endif
                dbrs_swid++;
              }
            }
          }
        }


        void ProcessAbstractReductionNetwork () {

          assert(num_levels_ >= 1);

          //Lowest level
          for(int inPrt = 0; inPrt < num_mult_switches_; inPrt++) {
            int vn_id = inPrt / vn_size_;
            int num_vns = num_mult_switches_ / vn_size_;
            auto compile_packet = std::make_shared<CompilePacket>(vn_id, vn_size_, 1);

            //            for (int sw = 0; sw < num_mult_switches_; sw++) {
            if(vn_id < num_vns) {
              if(inPrt <2) {
#ifdef DEBUG
                std::cout << "SGRS[" << num_levels_-1 << "][0] receives an initial packet to port " << inPrt %2 << std::endl;
#endif
                single_reduction_switches_[num_levels_-1][0]->PutPacket(compile_packet, inPrt %2 );
              }
              else if(inPrt > num_mult_switches_-3) {
#ifdef DEBUG
                std::cout << "SGRS[" << num_levels_-1 << "][1] receives an initial packet to port " << inPrt %2 << std::endl;
#endif
                single_reduction_switches_[num_levels_-1][1]->PutPacket(compile_packet, inPrt %2 );
              }
              else {
                int dbrs_id = (inPrt - 2)/4;
                int port_id = (inPrt -2) % 4;
#ifdef DEBUG
                std::cout << "DBRS[" << num_levels_-1 << "]["<< dbrs_id << "] receives an initial packet to port " << port_id << std::endl;
#endif
                double_reduction_switches_[num_levels_-1][dbrs_id]->PutPacket(compile_packet, port_id);
              }
            }
            //}
          }
#ifdef DEBUG
          std::cout << std::endl;
#endif

          //Process rest of the levels from the lowest level
          for(int lv = num_levels_-1; lv >= 0 ; lv--) {
            //Process packets within switches
            for(auto sgrs : single_reduction_switches_[lv]) {
              sgrs->ProcessPackets();
            }

            for(auto dbrs : double_reduction_switches_[lv]) {
              dbrs->ProcessPackets();
            }

            //Forward output packets to the upper level
            if(lv > 0) {
              /* Interconnect SGRSes */
              auto sgrs0_output = single_reduction_switches_[lv][0]->GetPacket(0);
              if(sgrs0_output != nullptr) {
#ifdef DEBUG
                std::cout << "SGRS[" << lv << "][0] Sends a packet to SGRS[" << lv-1 << "][0]" << std::endl;
#endif
                single_reduction_switches_[lv-1][0]->PutPacket(sgrs0_output, 0);
              }

              auto sgrs1_output = single_reduction_switches_[lv][1]->GetPacket(0);
              if(sgrs1_output != nullptr) {
                if(lv != 1) {
#ifdef DEBUG
                  std::cout << "SGRS[" << lv << "][1] Sends a packet to SGRS[" << lv-1 << "][1]" << std::endl;
#endif
                  single_reduction_switches_[lv-1][1]->PutPacket(sgrs1_output, 1);
                }
                else {
#ifdef DEBUG
                  std::cout << "SGRS[" << lv << "][1] Sends a packet to SGRS[" << lv-1 << "][0]" << std::endl;
#endif                  
                  single_reduction_switches_[lv-1][0]->PutPacket(sgrs1_output, 1);                  
                }
              }


              int num_dbrs_in_lv = GetNumDBRS(lv);
              int num_dbrs_in_prev_lv = GetNumDBRS(lv-1);

              std::cout << std::endl;

              if(lv > 1) {
                auto dbrs_lEdgeOutput = double_reduction_switches_[lv][0]->GetPacket(0);
                if(dbrs_lEdgeOutput != nullptr) {
#ifdef DEBUG
                  std::cout << "DBRS[" << lv << "][0]" << "Sends a packet to " << "SGRS[ " << lv -1 << "][0]" << std::endl;
#endif
                  single_reduction_switches_[lv-1][0]->PutPacket(dbrs_lEdgeOutput, 1);
                }

                auto dbrs_rEdgeOutput = double_reduction_switches_[lv][num_dbrs_in_lv-1]->GetPacket(1);
                if(dbrs_rEdgeOutput != nullptr) {
#ifdef DEBUG
                  std::cout << "DBRS[" << lv << "][" << num_dbrs_in_lv-1 << "]" << "Sends a packet to " << "SGRS[ " << lv -1 << "][1]" << std::endl;
                  std::cout <<"Packet: vnID: " << dbrs_rEdgeOutput->GetVNID() << ", vnSz: " << dbrs_rEdgeOutput->GetVNSize() << ", pSum: " << dbrs_rEdgeOutput->GetNumPSums() << std::endl;
#endif
                  single_reduction_switches_[lv-1][1]->PutPacket(dbrs_rEdgeOutput, 0);
                }

                std::cout << std::endl;

                if(lv>2) {
                  int num_dbrs_inPrt_in_prev_lv = num_dbrs_in_prev_lv * 4;

                  for(int dbrs_inPrt = 0; dbrs_inPrt < num_dbrs_inPrt_in_prev_lv; dbrs_inPrt++) {
                    int targ_input_sw_id = dbrs_inPrt/4;
                    int targ_input_sw_port = dbrs_inPrt % 4;
                    int targ_output_sw_id = (dbrs_inPrt+1)/2;
                    int targ_output_sw_port = (dbrs_inPrt+1) % 2;

                    auto packet = double_reduction_switches_[lv][targ_output_sw_id]->GetPacket(targ_output_sw_port);
                    if(packet != nullptr && !(targ_output_sw_id == 0 && targ_output_sw_port == 0) ) {
#ifdef DEBUG
                      std::cout << "DBRS[" << lv << "][" << targ_output_sw_id << "] Sends a packet from port " << targ_output_sw_port << " to DBRS[" << lv-1 << "][" << targ_input_sw_id << "] port" << targ_input_sw_port << std::endl;
#endif
                      double_reduction_switches_[lv-1][targ_input_sw_id]->PutPacket(packet, targ_input_sw_port);
                    }

                  } // End of for(int dbrs_inPrt = 0; dbrs_inPrt < num_dbrs_inPrt_in_prev_lv; dbrs_inPrt++)
                } // End of if (lv>2)
              } // End of if(lv>1)
            } // End of if(lv>0)
          } // end of for (lv = num_levels_-1; lv>=0; lv--)

          std::cout << "Finished processing reduction network information" << std::endl;
        }

        int GetNumDBRS(int target_level) {
          return static_cast<int>(pow(2, (target_level-1))) -1;
        }

        void PrintConfig() {
          int lv = 0;
          auto sgrs_config = this->GetSGRS_Config();
          auto dbrs_config = this->GetDBRS_Config();

          int sgrs_count = 0;
          for(auto it: *sgrs_config) {
            std::cout << "SGRS[" << sgrs_count << "]: " << it->ToString() << std::endl;
            sgrs_count++;
          }

          int dbrs_count = 0;
          for(auto it: *dbrs_config) {
            std::cout << "DBRS[" << dbrs_count << "]: " << it->ToString() << std::endl;
            dbrs_count++;
          }
        }

        std::shared_ptr<std::vector<std::shared_ptr<SGRS_Config>>> GetSGRS_Config() {
          std::shared_ptr<std::vector<std::shared_ptr<SGRS_Config>>> sgrs_configs = std::make_shared<std::vector<std::shared_ptr<SGRS_Config>>>();

          for(auto sgl_vec_it: single_reduction_switches_) {
            for(auto sgrs : sgl_vec_it) {
              auto config = std::make_shared<SGRS_Config>();
              config->genOutput_ = sgrs->GetGenOutput();
              config->mode_ = sgrs->GetMode();
              sgrs_configs->push_back(config);
            }
          }

          return sgrs_configs;
        }

        std::shared_ptr<std::vector<std::shared_ptr<DBRS_Config>>> GetDBRS_Config() {
          std::shared_ptr<std::vector<std::shared_ptr<DBRS_Config>>> dbrs_configs = std::make_shared<std::vector<std::shared_ptr<DBRS_Config>>>();

          for(auto dbl_vec_it: double_reduction_switches_) {
            for(auto dbrs : dbl_vec_it) {
              auto config = std::make_shared<DBRS_Config>();
              config->genOutputL_ = dbrs->GetGenOutputL();
              config->genOutputR_ = dbrs->GetGenOutputR();
              config->modeL_ = dbrs->GetModeL();
              config->modeR_ = dbrs->GetModeR();
              dbrs_configs->push_back(config);
            }
          }

          return dbrs_configs;
        }

    }; // End of class AbstractReductionNetwork
  }; // End of namespace ReductionNetwork
}; // End of namespace MAERI

#endif
