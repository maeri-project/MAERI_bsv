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

import Vector::*;
import Fifo::*;

import AcceleratorConfig::*;
import DataTypes::*;
import GenericInterface::*;
import RN_Types::*;

import RN_ReductionNetwork::*;

Bit#(32) test_cycles = 1000;

typedef 3 VN_ColSz;
typedef 3 VN_RowSz;

//This testbench assumes 32 MultSwitches

(* synthesize *)
module mkTestbench();

  RN_ReductionNetwork rn <- mkRN_ReductionNetwork;
  Vector#(NumMultSwitches, Reg#(Bit#(32))) sendCount <- replicateM(mkReg(0));  
  Vector#(CollectionBandwidth, Reg#(Bit#(32))) recvCount <- replicateM(mkReg(0));

//  Vector#(NumMultSwitches, Fifo#(5, Data)) ingressData <- replicateM(mkPipelineFifo);
//  Vector#(CollectionBandwidth, Fifo#(5, Data)) egressData <- replicateM(mkPipelineFifo);

  Reg#(Bit#(32)) cycleCount <- mkReg(0);

  rule finishTest;
    if(cycleCount == test_cycles) begin
      $display("==================================");
      for(Integer inPrt = 0; inPrt < valueOf(NumMultSwitches); inPrt = inPrt +1) begin
        $display("sendCount[%d] = %d", inPrt, sendCount[inPrt]);
      end
      $display("");
      for(Integer outPrt = 0; outPrt < valueOf(CollectionBandwidth); outPrt = outPrt +1) begin
        $display("recvCount[%d] = %d", outPrt, recvCount[outPrt]);        
      end

      $display("Note: Reduction factor: %d", valueOf(VN_ColSz) * valueOf(VN_RowSz));

      $finish;      
    end
  endrule

  rule incrementCounter;
    cycleCount <= cycleCount + 1;
  endrule

  rule configRN (cycleCount == 1);
      RN_Config testConfig;
      RN_SglRSNetworkConfig sgrs_cfg;
      RN_DblRSNetworkConfig dbrs_cfg;
     
      /* Manually generated test pattern */
      //SGRS configurations
      sgrs_cfg[0].mode = rn_sgrs_mode_idle;
      sgrs_cfg[0].genOutput = False;

      sgrs_cfg[1].mode = rn_sgrs_mode_idle;
      sgrs_cfg[1].genOutput = False;

      sgrs_cfg[2].mode = rn_sgrs_mode_addTwo;
      sgrs_cfg[2].genOutput = True;

      sgrs_cfg[3].mode = rn_sgrs_mode_addTwo;
      sgrs_cfg[3].genOutput = True;

      sgrs_cfg[4].mode = rn_sgrs_mode_flowLeft;
      sgrs_cfg[4].genOutput = False;

      sgrs_cfg[5].mode = rn_sgrs_mode_addTwo;
      sgrs_cfg[5].genOutput = False;

      sgrs_cfg[6].mode = rn_sgrs_mode_idle;
      sgrs_cfg[6].genOutput = False;

      sgrs_cfg[7].mode = rn_sgrs_mode_addTwo;
      sgrs_cfg[7].genOutput = False;

      sgrs_cfg[8].mode = rn_sgrs_mode_idle;
      sgrs_cfg[8].genOutput = False;

      //DBRS configurations
      dbrs_cfg[0].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[0].genOutputL = True;
      dbrs_cfg[0].genOutputR = False;

      dbrs_cfg[1].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[1].genOutputL = False;
      dbrs_cfg[1].genOutputR = False;

      dbrs_cfg[2].mode = {rn_dbrs_submode_addThree, rn_dbrs_submode_addOne};
      dbrs_cfg[2].genOutputL = False;
      dbrs_cfg[2].genOutputR = False;

      dbrs_cfg[3].mode = {rn_dbrs_submode_addThree, rn_dbrs_submode_addOne};
      dbrs_cfg[3].genOutputL = False;
      dbrs_cfg[3].genOutputR = False;

      dbrs_cfg[4].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[4].genOutputL = False;
      dbrs_cfg[4].genOutputR = False;

      dbrs_cfg[5].mode = {rn_dbrs_submode_addThree, rn_dbrs_submode_addOne};
      dbrs_cfg[5].genOutputL = False;
      dbrs_cfg[5].genOutputR = False;

      dbrs_cfg[6].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[6].genOutputL = False;
      dbrs_cfg[6].genOutputR = False;

      dbrs_cfg[7].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[7].genOutputL = False;
      dbrs_cfg[7].genOutputR = False;

      dbrs_cfg[8].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[8].genOutputL = False;
      dbrs_cfg[8].genOutputR = False;

      dbrs_cfg[9].mode = {rn_dbrs_submode_addTwo, rn_dbrs_submode_addTwo};
      dbrs_cfg[9].genOutputL = False;
      dbrs_cfg[9].genOutputR = False;

      dbrs_cfg[10].mode = {rn_dbrs_submode_addOne, rn_dbrs_submode_addThree};
      dbrs_cfg[10].genOutputL = False;
      dbrs_cfg[10].genOutputR = False;

      testConfig.sglRSNetworkConfig = sgrs_cfg;
      testConfig.dblRSNetworkConfig = dbrs_cfg;

      rn.controlPorts.putConfig(testConfig);
  endrule


  for(Integer inPrt = 0; inPrt < 27; inPrt = inPrt + 1) begin
    rule injectTestData(cycleCount > 2 && cycleCount < 9);
      Data iptData = fromInteger(inPrt) + truncate(cycleCount);
      rn.inputDataPorts[inPrt].putData(iptData);
      sendCount[inPrt] <= sendCount[inPrt] + 1;
    endrule
  end


  for(Integer outPrt = 0; outPrt < valueOf(CollectionBandwidth); outPrt = outPrt +1) begin
    rule collectOutputs;
      let outputData <- rn.outputDataPorts[outPrt].getData;
      recvCount[outPrt] <= recvCount[outPrt] + 1;
      $display("@ %d: received an output from switch %d", cycleCount, outPrt);
    endrule
  end

endmodule
