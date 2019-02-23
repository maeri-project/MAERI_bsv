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
import RWire::*;

import DataTypes::*;
import GenericInterface::*;

interface RN_SglReductionSwitch_EgressNIC_ControlPorts;
  method Action putGenOutput(Bool genOutputSig);
endinterface

interface RN_SglReductionSwitch_EgressNIC;
  interface RN_SglReductionSwitch_EgressNIC_ControlPorts controlPorts;
  interface GI_DataPorts dataPorts; 
  interface GI_OutputDataPorts resultsDataPorts;
endinterface

(* synthesize *)
module mkRN_SglReductionSwitch_EgressNIC(RN_SglReductionSwitch_EgressNIC);
  Fifo#(1, Data) outputBuffer <- mkPipelineFifo;
  Fifo#(1, Data) resultBuffer <- mkPipelineFifo;
  RWire#(Bool) genOutput <- mkRWire;

  interface controlPorts = 
    interface RN_SglReductionSwitch_EgressNIC_ControlPorts
      method Action putGenOutput(Bool genOutputSig);
        genOutput.wset(genOutputSig);
      endmethod
    endinterface;

  interface  dataPorts =
    interface GI_DataPorts
      method Action putData(Data data) if(isValid(genOutput.wget()));
        let genOutputSigValue = validValue(genOutput.wget());

        if(genOutputSigValue) begin
          resultBuffer.enq(data);
        end
        else begin
          outputBuffer.enq(data);
        end
      endmethod

      method ActionValue#(Data) getData;
        outputBuffer.deq;
        return outputBuffer.first;
      endmethod
    endinterface;

  interface resultsDataPorts = 
    interface GI_OutputDataPorts
      method ActionValue#(Data) getData;
        resultBuffer.deq;
        return resultBuffer.first;
      endmethod
    endinterface;

endmodule