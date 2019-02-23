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

import DN_Types::*;

interface DN_SubTree_Controller_ControlPorts;
  `ifdef DEBUG_DN
  method Action putSubTreeID(DN_NodeID newNodeID);
  `endif 

  method Action putNewDests(DN_SubTreeDestBits destBits);
  method Action putAckSignal;

  method DN_Epoch getEpoch;
  method ActionValue#(DN_SubTreeConfig) getConfiguration;
endinterface

interface DN_SubTree_Controller;
  interface DN_SubTree_Controller_ControlPorts controlPorts;
endinterface


(* synthesize *)
module mkDN_SubTree_Controller(DN_SubTree_Controller);

  `ifdef DEBUG_DN
  Reg#(DN_NodeID) subTreeID <- mkReg(0);
  `endif

  Reg#(DN_Epoch) epochReg <- mkReg(dn_initEpoch);
  Reg#(Bool) readyForNewData <- mkReg(True);
  Fifo#(DN_SubTreeIngressControlFifoDepth, DN_SubTreeDestBits) incomingDestBits <- mkBypassFifo;
  Fifo#(DN_SubTreeEgressControlFifoDepth, DN_SubTreeConfig) outConfigSignals <- mkPipelineFifo;

  function DN_SubTreeConfig computeConfigSignals(DN_SubTreeDestBits dBits);
    DN_SubTreeConfig controlSignal = newVector;

    //Lowest level;
    Integer lastLv = valueOf(DN_NumSubTreeLvs) -1;
    Integer lastLvFirstNodeID = 2 ** lastLv - 1;
    Integer numNodesInLastLv = 2 ** lastLv;

    for(Integer node = 0; node < numNodesInLastLv ; node = node +1) begin
      Integer nodeID = lastLvFirstNodeID + node;

      Bool leftFwd = (dBits[2*node] != 1'b0);
      Bool rightFwd = (dBits[2*node+1] != 1'b0);

      if(leftFwd && rightFwd) begin
        controlSignal[nodeID] = ds_both;
      end
      else if(leftFwd) begin
        controlSignal[nodeID] = ds_left;
      end
      else if(rightFwd) begin
        controlSignal[nodeID] = ds_right;
      end
      else begin
        controlSignal[nodeID] = ds_idle;
      end
    end

    for(Integer lv = valueOf(DN_NumSubTreeLvs)-2; lv >= 0;  lv = lv - 1) begin
      Integer lvFirstNodeID = 2 ** lv - 1;
      Integer nextLvFirstNodeID = 2 ** (lv+1) -1;
      Integer numNodesInLv = 2 ** lv;
      Integer dBitWindowSz = 2 ** (valueOf(DN_NumSubTreeLvs) - lv -1);

      for(Integer node = 0; node < numNodesInLv ; node = node +1) begin
        Integer nodeID = lvFirstNodeID + node;
        Integer leftChildID =  nextLvFirstNodeID + 2 * node;
        Integer rightChildID = leftChildID + 1;

        Bool leftFwd = (controlSignal[leftChildID] != ds_idle);
        Bool rightFwd = (controlSignal[rightChildID] != ds_idle);

        if(leftFwd && rightFwd) begin
          controlSignal[nodeID] = ds_both;
        end
        else if(leftFwd) begin
          controlSignal[nodeID] = ds_left;
        end
        else if(rightFwd) begin
          controlSignal[nodeID] = ds_right;
        end
        else begin
          controlSignal[nodeID] = ds_idle;
        end

      end
    end

    return controlSignal;
  endfunction

  rule generateConfigSignals(incomingDestBits.notEmpty);
    let newControl = computeConfigSignals(incomingDestBits.first);
    incomingDestBits.deq;
    outConfigSignals.enq(newControl);
  endrule

  interface controlPorts =
    interface DN_SubTree_Controller_ControlPorts
      `ifdef DEBUG_DN
        method Action putSubTreeID(DN_NodeID newSubTreeID);
          subTreeID <= newSubTreeID;
        endmethod
      `endif

      method Action putNewDests(DN_SubTreeDestBits destBits);
        incomingDestBits.enq(destBits);
      endmethod

      method Action putAckSignal if(!readyForNewData);
        readyForNewData <= True;
      endmethod

      method DN_Epoch getEpoch;
        return epochReg;
      endmethod

      method ActionValue#(DN_SubTreeConfig) getConfiguration if(readyForNewData);
        epochReg <= ~epochReg; // Green signal to the next traffic
        readyForNewData <= False;
        outConfigSignals.deq;

        `ifdef DEBUG_DN
        `ifdef DEBUG_DN_SUBTREE_CONTROLLER
          let outputConfig = outConfigSignals.first;
          $display("[DN_SubTree_Controller] SubTree ID %d", subTreeID);
         for(Integer sw = 0; sw < valueOf(DN_NumSubTreeDistSwitches); sw = sw + 1) begin
            $display("\t new Config signal[%d] = %b", sw, outputConfig[sw]);
          end
        `endif
        `endif
        return outConfigSignals.first;
      endmethod

   endinterface;

endmodule
