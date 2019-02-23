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

interface RN_DblReductionSwitch_EgressNIC_ControlPorts;
  method Action putGenOutputL(Bool genOutputLSig);
  method Action putGenOutputR(Bool genOutputRSig);
endinterface

interface RN_DblReductionSwitch_EgressNIC;
  interface RN_DblReductionSwitch_EgressNIC_ControlPorts controlPorts;
  interface Vector#(2, GI_DataPorts) dataPorts; 
  interface Vector#(2, GI_OutputDataPorts) resultsDataPorts;
endinterface

(* synthesize *)
module mkRN_DblReductionSwitch_EgressNIC(RN_DblReductionSwitch_EgressNIC);
  Vector#(2, Fifo#(1, Data)) outputBuffers <- replicateM(mkPipelineFifo);
  Vector#(2, Fifo#(1, Data)) resultBuffers <- replicateM(mkPipelineFifo);
  Vector#(2, RWire#(Bool)) genOutput <- replicateM(mkRWire);

  Vector#(2, GI_DataPorts) dataPortsDef;
  for(Integer prt = 0; prt < 2; prt = prt +1) begin
    dataPortsDef[prt] =
      interface GI_DataPorts
        method Action putData(Data data) if (isValid(genOutput[prt].wget()));
          if(validValue(genOutput[prt].wget()) == True) begin
            resultBuffers[prt].enq(data);
          end
          else begin
            outputBuffers[prt].enq(data);
          end
        endmethod

        method ActionValue#(Data) getData;
          outputBuffers[prt].deq;
          return outputBuffers[prt].first;
        endmethod

      endinterface;
  end

  Vector#(2, GI_OutputDataPorts) resultsDataPortsDef;
  for(Integer prt = 0; prt < 2; prt = prt +1) begin
    resultsDataPortsDef[prt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          resultBuffers[prt].deq;
          return resultBuffers[prt].first;
        endmethod
      endinterface;
  end

  interface dataPorts = dataPortsDef;
  interface resultsDataPorts = resultsDataPortsDef;
  interface controlPorts = 
    interface RN_DblReductionSwitch_EgressNIC_ControlPorts
      method Action putGenOutputL(Bool genOutputLSig);
      genOutput[0].wset(genOutputLSig);
      endmethod

      method Action putGenOutputR(Bool genOutputRSig);
        genOutput[1].wset(genOutputRSig);
      endmethod
    endinterface;


endmodule