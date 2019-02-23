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

interface DistributionSubTreeUpstreamNICControlPorts;
  method DN_Epoch getEpoch;
  method Bool isEmpty;
endinterface

interface DN_SubTree_IngressNIC;
  interface DistributionSubTreeUpstreamNICControlPorts controlPorts;
  interface GI_DataPorts dataPorts;
endinterface


(* synthesize *)
module mkDN_SubTree_IngressNIC(DN_SubTree_IngressNIC);
  Reg#(DN_Epoch) epochReg <- mkReg(dn_initEpoch);
  Fifo#(DN_SubTreeIngressFifoDepth, Data) incomingData <- mkPipelineFifo;
  Fifo#(DN_SubTreeIngressFifoDepth, DN_Epoch) epochStore <- mkPipelineFifo;

  interface dataPorts =
    interface GI_DataPorts
      method Action putData(Data data);
        incomingData.enq(data);
        epochStore.enq(~epochReg);
        epochReg <= ~epochReg;
      endmethod

      method ActionValue#(Data) getData;
        incomingData.deq;
        epochStore.deq;
        return incomingData.first;
      endmethod
    endinterface;

  interface controlPorts = 
    interface DistributionSubTreeUpstreamNICControlPorts
      method DN_Epoch getEpoch;
        return epochStore.first;
      endmethod

      method Bool isEmpty;
        return !incomingData.notEmpty;
      endmethod
    endinterface;

endmodule
