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
import Connectable::*;

import AcceleratorConfig::*;
import DataTypes::*;
import DN_Types::*;
import GenericInterface::*;

import DN_SubTree_IngressNIC::*;
import DN_SubTree_EgressNIC::*;
import DN_SubTree_Controller::*;

import DN_DistributionSwitch::*;

interface DN_SubTree_ControlPorts;
  `ifdef DEBUG_DN
   method Action putSubTreeID(DN_NodeID newSubTreeID);
  `endif
  method Bool isEmpty;
  method Action putNewDests(DN_SubTreeDestBits destBits);
endinterface

interface DN_SubTree;
  interface DN_SubTree_ControlPorts controlPorts;  

  interface GI_InputDataPorts inputDataPorts;
  interface Vector#(DN_SubTreeSz, GI_OutputDataPorts) outputDataPorts;
endinterface

(* synthesize *)
module mkDN_SubTree(DN_SubTree);

  `ifdef DEBUG_DN
    Reg#(Maybe#(DN_NodeID)) subTreeID <- mkReg(Invalid);
    Reg#(Bool) inited <- mkReg(False);
  `endif

  Vector#(DN_NumSubTreeDistSwitches, DN_DistributionSwitch) distSwitches <- replicateM(mkDN_DistributionSwitch);
  DN_SubTree_IngressNIC ingressNIC <- mkDN_SubTree_IngressNIC;
  DN_SubTree_EgressNIC egressNIC <- mkDN_SubTree_EgressNIC;

  DN_SubTree_Controller controller <- mkDN_SubTree_Controller;

  /* Tree Datapath  connection */
  for(Integer lv = 0; lv < valueOf(DN_NumSubTreeLvs)-1; lv = lv + 1) begin
    Integer lvFirstNodeID = 2 ** lv - 1;
    Integer nextLvFirstNodeID = 2 ** (lv+1) -1;
    Integer numNodes = 2 ** lv;

    for(Integer node = 0; node < numNodes ; node = node +1) begin
      Integer firstTargNodeID = nextLvFirstNodeID + node * 2;
      
      mkConnection(distSwitches[lvFirstNodeID + node].dataPorts.getDataL,
                     distSwitches[firstTargNodeID].dataPorts.putData);

      mkConnection(distSwitches[lvFirstNodeID + node].dataPorts.getDataR,
                     distSwitches[firstTargNodeID+1].dataPorts.putData);
    end
  end

  /* Connect tree leaves and NIC */
  Integer lastLvFirstNodeID = 2 ** (valueOf(DN_NumSubTreeLvs)-1) -1;
  for(Integer sw = 0; sw < valueOf(DN_SubTreeSz); sw = sw +1) begin // Only iterates over the lowest level switches
    if(sw %2 == 0) begin
      mkConnection(distSwitches[lastLvFirstNodeID + sw/2].dataPorts.getDataL, egressNIC.dataPorts[sw].putData);
    end
    else begin
      mkConnection(distSwitches[lastLvFirstNodeID + sw/2].dataPorts.getDataR, egressNIC.dataPorts[sw].putData);
    end
  end

  `ifdef DEBUG_DN
  rule initialize(!inited && isValid(subTreeID));
    let baseIdx = validValue(subTreeID) * fromInteger(valueOf(DN_SubTreeSz));
    for(Integer sw = 0; sw < valueOf(DN_NumSubTreeDistSwitches); sw = sw+1) begin
      distSwitches[sw].controlPorts.putNodeID(baseIdx + fromInteger(sw));
    end
    inited <= True;
  endrule
  `endif

  rule sendData(controller.controlPorts.getEpoch == ingressNIC.controlPorts.getEpoch);
    let newData <- ingressNIC.dataPorts.getData;
    distSwitches[0].dataPorts.putData(newData);
    controller.controlPorts.putAckSignal;
  endrule

  rule configureTree;
    let newConfig <- controller.controlPorts.getConfiguration; // This will fire only if it is safe to reconfigure the tree
 
    for(Integer sw = 0; sw < valueOf(DN_NumSubTreeDistSwitches); sw = sw+1) begin
      distSwitches[sw].controlPorts.putNewConfig(newConfig[sw]);
    end
  endrule
 
  /* Interface */
  Vector#(DN_SubTreeSz, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer sw = 0; sw < valueOf(DN_SubTreeSz); sw = sw +1) begin
    outputDataPortsDef[sw] = 
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          let ret <- egressNIC.dataPorts[sw].getData;
          return ret;
        endmethod
      endinterface;
  end

  interface outputDataPorts = outputDataPortsDef;

  interface inputDataPorts = 
    interface GI_InputDataPorts
      method Action putData(Data data);
        ingressNIC.dataPorts.putData(data);
      endmethod
    endinterface ;

  interface controlPorts =
    interface DN_SubTree_ControlPorts
      `ifdef DEBUG_DN
        method Action putSubTreeID(DN_NodeID newSubTreeID);
          subTreeID <= Valid(newSubTreeID);
        endmethod
      `endif

      method Bool isEmpty;
        return ingressNIC.controlPorts.isEmpty;
      endmethod

      method Action putNewDests(DN_SubTreeDestBits destBits);
      `ifdef DEBUG_DN
      `ifdef DEBUG_DN_SUBTREE
         $display("[DN_SubTree] SubTree %d received destBits %b", validValue(subTreeID), destBits);
      `endif
      `endif      
        controller.controlPorts.putNewDests(destBits);
      endmethod
    endinterface;

 
endmodule

