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
import DN_Types::*;


interface DN_EgressNIC_DataPorts;
  method Action putData(Data data);
  method ActionValue#(Data) getData;
endinterface


interface DN_EgressNIC;
  interface Vector#(NumMultSwitches, DN_EgressNIC_DataPorts) dataPorts;
endinterface


(* synthesize *)
module mkDN_EgressNIC(DN_EgressNIC);

  Vector#(NumMultSwitches, Fifo#(DN_EgressFifoDepth, Data)) outputBuffers  <- replicateM(mkBypassFifo);

  Vector#(NumMultSwitches, DN_EgressNIC_DataPorts) dataPortsDef;
  for(Integer prt = 0; prt < valueOf(NumMultSwitches); prt=prt+1) begin
    dataPortsDef[prt] =
      interface DN_EgressNIC_DataPorts
        method Action putData(Data data);
          outputBuffers[prt].enq(data);
        endmethod

        method ActionValue#(Data) getData;
          outputBuffers[prt].deq;
          return outputBuffers[prt].first;
        endmethod
      endinterface;
  end

  interface dataPorts = dataPortsDef;
endmodule