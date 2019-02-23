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
import Connectable::*;
import GenericInterface::*;

import AcceleratorConfig::*;
import DataTypes::*;
import DN_Types::*;


import DN_SubTree::*;

import DN_DistributionNetwork_IngressNIC::*;
import DN_DistributionNetwork_EgressNIC::*;



interface DN_ControlPorts;
  method Action putConfig(DN_TopSubTreeConfig newConfig);
endinterface

interface DN_DistributionNetwork;
  method Bool isEmpty;
  interface Vector#(DN_NumSubTrees,  DN_ControlPorts) controlPorts;
  interface Vector#(DN_NumSubTrees, GI_InputDataPorts) inputDataPorts;
  interface Vector#(NumMultSwitches, GI_OutputDataPorts) outputDataPorts;
endinterface

(* synthesize *)
module mkDN_DistributionNetwork(DN_DistributionNetwork);
  `ifdef DEBUG_DN
  Reg#(Bool) inited <- mkReg(False);
  `endif
  DN_IngressNIC ingressNIC <- mkDN_IngressNIC;
  DN_EgressNIC egressNIC   <- mkDN_EgressNIC;

  Vector#(DN_NumSubTrees, DN_SubTree) subTrees <- replicateM(mkDN_SubTree);

  /* Interconnect roots of SubTrees to upsteream (input) NIC */
  for(Integer subTreeID = 0; subTreeID < valueOf(DN_NumSubTrees); subTreeID = subTreeID + 1) begin
    mkConnection(ingressNIC.dataPorts[subTreeID].getData,
                  subTrees[subTreeID].inputDataPorts.putData);
  end

  /* Interconnect leaves of SubTrees to downstream (output) NIC */
  for(Integer subTreeID = 0; subTreeID < valueOf(DN_NumSubTrees); subTreeID = subTreeID + 1) begin
    for(Integer outPrt = 0; outPrt < valueOf(DN_SubTreeSz); outPrt = outPrt+1) begin
      mkConnection(subTrees[subTreeID].outputDataPorts[outPrt].getData,
                     egressNIC.dataPorts[subTreeID * valueOf(DN_SubTreeSz) +  outPrt].putData);
    end
  end

  `ifdef DEBUG_DN
  rule doInit(!inited);
    for(DN_NodeID idx = 0; idx < fromInteger(valueOf(DN_NumSubTrees)); idx = idx + 1) begin
      subTrees[idx].controlPorts.putSubTreeID(idx);
    end
    inited <= True;
  endrule
  `endif

  /* Interfaces */
  Vector#(DN_NumSubTrees,  DN_ControlPorts) controlPortsDef;
  Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPortsDef;
  Vector#(NumMultSwitches, GI_OutputDataPorts) outputDataPortsDef;

  for(Integer prt = 0; prt< valueOf(DistributionBandwidth); prt = prt+1) begin
    controlPortsDef[prt] = 
      interface DN_ControlPorts
        method Action putConfig(DN_TopSubTreeConfig dBits);
          `ifdef DEBUG_DN
            $display("[DN]  DN received a config %b from input port %d", dBits, prt);
          `endif        
          subTrees[prt].controlPorts.putNewDests(dBits);
        endmethod
      endinterface;
  end

  for(Integer prt = 0; prt< valueOf(DistributionBandwidth); prt = prt+1) begin
    inputDataPortsDef[prt] = 
      interface GI_InputDataPorts
        method Action putData(Data data);
          `ifdef DEBUG_DN
            $display("[DN] DN received a data from input port %d", prt);
          `endif
          ingressNIC.dataPorts[prt].putData(data);          
        endmethod
      endinterface;
  end

  for(Integer prt = 0; prt < valueOf(NumMultSwitches); prt = prt+1) begin
    outputDataPortsDef[prt] = 
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          `ifdef DEBUG_DN
            $display("[DN]  DN outputs data to port %d", prt);
          `endif
          let ret <- egressNIC.dataPorts[prt].getData;
          return ret;
        endmethod
      endinterface;
  end

  interface controlPorts = controlPortsDef;
  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = outputDataPortsDef;

  method Bool isEmpty;
    Bool ret = True;

    for(Integer subTree = 0; subTree < valueOf(DN_NumSubTrees); subTree= subTree + 1) begin
      if(ret && subTrees[subTree].controlPorts.isEmpty) begin
        ret = True;
      end
      else begin
        ret = False;
      end
    end

    if(ret && !ingressNIC.isEmpty) begin
      ret = False;
    end

    return ret;
  endmethod

endmodule
