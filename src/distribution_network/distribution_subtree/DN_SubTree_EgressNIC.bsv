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
import GenericInterface::*;

interface DN_SubTree_EgressNIC; 
  interface Vector#(DN_SubTreeSz, GI_DataPorts) dataPorts;
endinterface

(* synthesize *)
module mkDN_SubTree_EgressNIC(DN_SubTree_EgressNIC);
  Vector#(DN_SubTreeSz, Fifo#(1, Data)) outData <- replicateM(mkBypassFifo); //Implements latency-insensitive end

  Vector#(DN_SubTreeSz, GI_DataPorts) dataPortsDef;
  for(Integer outSw = 0; outSw < valueOf(DN_SubTreeSz); outSw = outSw +1) begin
    dataPortsDef[outSw] = 
      interface GI_DataPorts
        method Action putData(Data data);
          outData[outSw].enq(data);
        endmethod

        method ActionValue#(Data) getData;
          outData[outSw].deq;
          return outData[outSw].first;
        endmethod
      endinterface;
  end

  interface dataPorts = dataPortsDef;
endmodule
