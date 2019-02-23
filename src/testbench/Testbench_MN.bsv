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

import AcceleratorConfig::*;
import DataTypes::*;
import GenericInterface::*;
import MN_Types::*;

import MN_MultiplierNetwork::*;

Bit#(32) test_cycles = 1000;
typedef 3 VN_ColSz;

(* synthesize *)
module mkTestbench();

  MN_MultiplierNetwork mn <- mkMN_MultiplierNetwork;
  Vector#(NumMultSwitches, Reg#(Bit#(32))) pSumCount <- replicateM(mkReg(0));

  Reg#(Bit#(32)) cycleCount <- mkReg(0);

  rule finishTest;
    if(cycleCount == test_cycles) begin
      $display("==================================");
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        $display("pSumCount[%d] = %d", sw, pSumCount[sw]);
      end

      $finish;      
    end
  endrule

  rule incrementCounter;
    cycleCount <= cycleCount + 1;
  endrule


  rule generateControlSignal;
    if(cycleCount == 0 || cycleCount == 9) begin
      $display("@ %d: Sending out initiaialization config", cycleCount);

      MN_Config newConfig = newVector;
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
          newConfig[sw].state = ms_initSteadyVal;
          newConfig[sw].psumCount = 0;
      end
      mn.controlPorts.putConfig(newConfig);
    end
    else if(cycleCount == 2 || cycleCount == 11) begin
      $display("@ %d: Sending out configs", cycleCount);
      MN_Config newConfig = newVector;
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        if(sw % valueOf(VN_ColSz) == 0 ) begin
          newConfig[sw].state = ms_runLEdgeFirst;
          newConfig[sw].psumCount = 3;
        end
        else if(sw % valueOf(VN_ColSz) == valueOf(VN_ColSz)-1 ) begin
          newConfig[sw].state = ms_runREdgeFirst;   
          newConfig[sw].psumCount = 3;
        end
        else begin
          newConfig[sw].state = ms_runMiddleFirst;   
          newConfig[sw].psumCount = 3;         
        end
      end
      mn.controlPorts.putConfig(newConfig);
    end

  endrule


  rule generateTestdataStream;
    if(cycleCount == 1 || cycleCount ==  10 ) begin
      $display("@ %d: weight initialization", cycleCount);
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        let inData = fromInteger(sw);
        mn.dataPorts[sw].putData(inData);
      end
    end
    else if(cycleCount == 3 || cycleCount == 4 || cycleCount == 5 || cycleCount == 12 || cycleCount == 13 || cycleCount == 14 || cycleCount == 15) begin
      $display("@ %d: input multicast", cycleCount);
      for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
        if(sw % valueOf(VN_ColSz) == 0 ) begin
          let inData = fromInteger(sw);
          mn.dataPorts[sw].putData(inData);
        end
      end
    end
  endrule


  for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
    rule collectOutputs;
      let outputData <- mn.dataPorts[sw].getData;
      pSumCount[sw] <= pSumCount[sw] + 1;
      $display("@ %d: received an output from switch %d", cycleCount, sw);
    endrule
  end

endmodule
