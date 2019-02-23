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


import AcceleratorConfig::*;


import RN_Types::*;
import CR_Types::*;

import CR_ConfigurationMemory::*;


typedef 150 FinalCycle;

(* synthesize *)
module mkTestbench();
  Reg#(Bit#(16)) cycleCounter <- mkReg(0);

  CR_ConifgurationMemory configMem <- mkCR_ConfigurationMemory;

  rule runTestbench;
    if(cycleCounter == fromInteger(valueOf(FinalCycle)) ) begin
      $finish;
    end
    else begin
      cycleCounter <= cycleCounter + 1;
    end
  endrule

  rule readConfig;
  
    let newRNConfig <- configMem.getRN_Config;
    $display("Received config at cycle %d", cycleCounter);

    for(Integer dbrs = 0; dbrs < valueOf(RN_NumDblRSes); dbrs = dbrs +1 ) begin
      let mode = newRNConfig.dblRSNetworkConfig[dbrs].mode;
      RN_DBRS_SubMode modeL = truncateLSB(mode);
      RN_DBRS_SubMode modeR = truncate(mode);

      let genOutputL = newRNConfig.dblRSNetworkConfig[dbrs].genOutputL;
      let genOutputR = newRNConfig.dblRSNetworkConfig[dbrs].genOutputR;

      $display("DBRS %d config", dbrs);
      $display("ModeL: %b    , ModeR: %b", modeL, modeR);
      if(genOutputL) begin
        $display("Generates an output at Left");
      end

      if(genOutputR) begin
        $display("Generates an output at Right");
      end

    end

    for(Integer sgrs = 0; sgrs < valueOf(RN_NumSglRSes); sgrs = sgrs +1 ) begin
      let mode = newRNConfig. sglRSNetworkConfig[sgrs].mode;
      let genOutput = newRNConfig. sglRSNetworkConfig[sgrs].genOutput;

      $display("SGRS %d config", sgrs);
      $display("Mode: %b", mode);
      if(genOutput) begin
        $display("Generates an output");
      end
    end


  endrule


endmodule