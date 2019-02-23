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


interface DN_IngressNIC_DataPorts;
  method Action putData(Data data);
  method ActionValue#(Data) getData;
endinterface


interface DN_IngressNIC;
  method Bool isEmpty;
  interface Vector#(DN_NumSubTrees, DN_IngressNIC_DataPorts) dataPorts;
endinterface


(* synthesize *)
module mkDN_IngressNIC(DN_IngressNIC);

  Vector#(DistributionBandwidth, Fifo#(DN_IngressFifoDepth, Data)) inputBuffers  <- replicateM(mkPipelineFifo);

  Vector#(DN_NumSubTrees, DN_IngressNIC_DataPorts) dataPortsDef;
  for(Integer prt = 0; prt < valueOf(DN_NumSubTrees); prt=prt+1) begin
    dataPortsDef[prt] =
      interface DN_IngressNIC_DataPorts
        method Action putData(Data data);
          inputBuffers[prt].enq(data);
        endmethod

        method ActionValue#(Data) getData;
          inputBuffers[prt].deq;
          return inputBuffers[prt].first;
        endmethod
      endinterface;
  end

  interface dataPorts = dataPortsDef;

  method Bool isEmpty;
    Bool ret = True;
    for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt +1) begin
      if(ret && !inputBuffers[prt].notEmpty) begin
        ret =  True;
      end
      else begin
        ret = False;
      end
    end

    return ret;
  endmethod


endmodule