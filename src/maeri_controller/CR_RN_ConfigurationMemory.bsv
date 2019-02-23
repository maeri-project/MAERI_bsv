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


import RegFile::*;
import Fifo::*;

import RN_Types::*;
import CR_Types::*;


interface CR_RN_ConifgurationMemory;
  method ActionValue#(RN_Config) getRN_Config;
endinterface

(* synthesize *)
module mkCR_RN_ConfigurationMemory(CR_RN_ConifgurationMemory);

  RegFile#(CR_ConfigIdx, CR_ConfigData)   configMem      <- mkRegFileFullLoad("RN_Config.vmh");

  Reg#(Bool) active <- mkReg(True);
  Reg#(CR_ConfigIdx) processCounter <- mkReg(0);
  Reg#(RN_Config) rnConfigBuffer <- mkRegU;

  Fifo#(1, RN_Config) rnConfigFifo <- mkPipelineFifo;

  rule getConfig(active);
    let rawConfigData = configMem.sub(processCounter);
    //$display("ProcessCounter: %d", processCounter);

    if(processCounter < fromInteger(valueOf(CR_DBRS_ConfigAddressBound)) ) begin
      CR_ConfigIdx dbrs_base_idx = processCounter * 4;

      RN_Config currentConfig = rnConfigBuffer;

      for(CR_ConfigIdx ofs = 0; ofs < 4; ofs = ofs + 1) begin
        if(dbrs_base_idx + ofs < fromInteger(valueOf(RN_NumDblRSes))) begin
          CR_DBRS_ConfigData targetConfig = getCR_DBRS_ConfigData(rawConfigData, truncate(ofs)); 
          currentConfig.dblRSNetworkConfig[dbrs_base_idx+ofs].mode = getDBRS_ModeFromRawData(targetConfig);
          currentConfig.dblRSNetworkConfig[dbrs_base_idx+ofs].genOutputL = getDBRS_GenOutputL(targetConfig);
          currentConfig.dblRSNetworkConfig[dbrs_base_idx+ofs].genOutputR = getDBRS_GenOutputR(targetConfig);
        end
      end

      rnConfigBuffer <= currentConfig;
    end
    else if (processCounter < fromInteger(valueOf(CR_SGRS_ConfigAddressBound))) begin
      CR_ConfigIdx sgrs_base_idx = (processCounter - fromInteger(valueOf(CR_DBRS_ConfigAddressBound))) * 8;


      RN_Config currentConfig = rnConfigBuffer;

      for(CR_ConfigIdx ofs = 0; ofs < 8; ofs = ofs + 1) begin
        if(sgrs_base_idx + ofs < fromInteger(valueOf(RN_NumSglRSes))) begin
          CR_SGRS_ConfigData targetConfig = getCR_SGRS_ConfigData(rawConfigData, truncate(ofs)); 
          currentConfig.sglRSNetworkConfig[sgrs_base_idx+ofs].mode = getSGRS_ModeFromRawData(targetConfig);
          currentConfig.sglRSNetworkConfig[sgrs_base_idx+ofs].genOutput = getSGRS_GenOutput(targetConfig);
        end
      end

      rnConfigBuffer <= currentConfig;
    end
    else begin
      rnConfigFifo.enq(rnConfigBuffer);
      active <= False;
    end

    processCounter <= processCounter + 1;

  endrule

  method ActionValue#(RN_Config) getRN_Config;
    rnConfigFifo.deq;
    return rnConfigFifo.first;
  endmethod


endmodule