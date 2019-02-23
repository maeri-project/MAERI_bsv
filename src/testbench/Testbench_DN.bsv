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
import DN_Types::*;

import DN_DistributionNetwork::*;

Bit#(32) test_cycles = 1000;

typedef 3 VN_ColSz;

(* synthesize *)
module mkTestbench();

  DN_DistributionNetwork dn <- mkDN_DistributionNetwork;
  Vector#(NumMultSwitches, Reg#(Bit#(32))) sendCount <- replicateM(mkReg(0));  
  Vector#(NumMultSwitches, Reg#(Bit#(32))) recvCount <- replicateM(mkReg(0));

  Vector#(DN_NumSubTrees, Fifo#(5, Data)) ingressData <- replicateM(mkPipelineFifo);

  Reg#(Bit#(32)) cycleCount <- mkReg(0);

  rule finishTest;
    if(cycleCount == test_cycles) begin
      $display("==================================");
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        $display("sendCount[%d] = %d", sw, sendCount[sw]);
      end
      $display("");
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        $display("recvCount[%d] = %d", sw, recvCount[sw]);        
      end


      $finish;      
    end
  endrule

  rule incrementCounter;
    cycleCount <= cycleCount + 1;
  endrule


  rule generateTestInputs;
    if(fromInteger(valueOf(NumMultSwitches)) <= cycleCount && cycleCount < 2 * fromInteger(valueOf(NumMultSwitches))) begin
      $display("Unicast test");
      $display("@ %d: Sending out unicast traffic to switch %d", cycleCount, cycleCount - fromInteger(valueOf(NumMultSwitches)));

      DN_Config newConfig = 0;

      Bit#(TAdd#(TLog#(NumMultSwitches),1)) swIdx = truncate(cycleCount - fromInteger(valueOf(NumMultSwitches)));
      newConfig[swIdx] = 1;


      Vector#(DN_NumSubTrees, DN_SubTreeDestBits) subTreeConfigs = newVector;

      $display("[Testbench] Dest bit = %b. SwIdx = %d", newConfig, swIdx);
      for(Integer subTree = 0; subTree < valueOf(DN_NumSubTrees); subTree = subTree + 1) begin
        let subTreeDBits = getSubTreeConfig(newConfig, fromInteger(subTree));
        $display("[Testbench] Subtree %d Dbits: %b", subTree, subTreeDBits);
        if(subTreeDBits != 0) begin
          dn.controlPorts[subTree].putConfig(subTreeDBits);
          ingressData[subTree].enq(truncate(cycleCount) + fromInteger(subTree));
        end
      end

      for(Integer sw = 0; sw <valueOf(NumMultSwitches); sw = sw+1) begin
        if(newConfig[sw] != 0) begin
          sendCount[sw] <= sendCount[sw] + 1;
        end
      end
    end
    else if(fromInteger(valueOf(NumMultSwitches)) * 3 <= cycleCount && cycleCount < 4 * fromInteger(valueOf(NumMultSwitches))) begin
      $display("Multicast test");

      DN_Config newConfig = 0;

      for(Integer sw = 0; sw < valueOf(NumMultSwitches) ; sw = sw +1) begin
        if(sw % valueOf(VN_ColSz) == 0) begin
          newConfig[sw] = 1;
          sendCount[sw] <= sendCount[sw] + 1;          
        end
      end
      
      $display("@ %d: Sending out unicast traffic to switches. Dest bits =  %b", cycleCount, newConfig);

      for(Integer subTree = 0; subTree < valueOf(DN_NumSubTrees); subTree = subTree + 1) begin
        let subTreeDBits = getSubTreeConfig(newConfig, fromInteger(subTree));
        $display("[Testbench] Subtree %d Dbits: %b", subTree, subTreeDBits);
        if(subTreeDBits != 0) begin
          dn.controlPorts[subTree].putConfig(subTreeDBits);
          ingressData[subTree].enq(truncate(cycleCount) + fromInteger(subTree));
        end
      end
    
    end

  endrule

  for(Integer inPrt = 0; inPrt < valueOf(DN_NumSubTrees); inPrt = inPrt + 1) begin
    rule injectTestData;
      dn.inputDataPorts[inPrt].putData(ingressData[inPrt].first);
      ingressData[inPrt].deq;
    endrule
  end

  for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
    rule collectOutputs;
      let outputData <- dn.outputDataPorts[sw].getData;
      recvCount[sw] <= recvCount[sw] + 1;
      $display("@ %d: received an output from switch %d", cycleCount, sw);
    endrule
  end

endmodule
