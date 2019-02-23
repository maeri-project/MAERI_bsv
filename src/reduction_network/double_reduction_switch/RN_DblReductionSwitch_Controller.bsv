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

import RN_Types::*;

interface RN_DblReductionSwitch_Controller_ControlPorts;
  `ifdef DEBUG_RN
    method Action initialize(RN_NodeID newNodeID);
  `endif

  method Action putConfig(RN_DblRSConfig newConfig); 

  method Bool getGenOutputL;
  method Bool getGenOutputR;

  method RN_DBRS_SubMode getModeL;
  method RN_DBRS_SubMode getModeR;  
endinterface

interface RN_DblReductionSwitch_Controller;
  interface RN_DblReductionSwitch_Controller_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkRN_DblReductionSwitch_Controller(RN_DblReductionSwitch_Controller);
  `ifdef DEBUG_RN
  Reg#(RN_NodeID) nodeID <- mkReg(0);
  `endif

  Reg#(RN_DBRS_SubMode) leftMode       <- mkReg(rn_dbrs_submode_idle);
  Reg#(RN_DBRS_SubMode) rightMode      <- mkReg(rn_dbrs_submode_idle);
  Reg#(Bool)            leftGenOutput  <- mkReg(False);
  Reg#(Bool)            rightGenOutput <- mkReg(False);


  interface controlPorts =
    interface RN_DblReductionSwitch_Controller_ControlPorts

      `ifdef DEBUG_RN
        method Action initialize(RN_NodeID newNodeID);
          nodeID <= newNodeID;
        endmethod
      `endif

      method Action putConfig(RN_DblRSConfig newConfig); 
        RN_DBRS_SubMode newModeL = truncateLSB(newConfig.mode);
        RN_DBRS_SubMode newModeR = truncate(newConfig.mode);
        `ifdef DEBUG_RN
        `ifdef DEBUG_RN_RS_CONTROLLER
          $display("Double Reduction Switch %d, ModeL: %b, ModeR: %b, leftGenOutput: %b, rightGenOutput: %b", nodeID, newModeL, newModeR, newConfig.genOutputL, newConfig.genOutputR);
        `endif
        `endif

        leftMode <= newModeL;
        rightMode <= newModeR;

        leftGenOutput <= newConfig.genOutputL; 
        rightGenOutput <= newConfig.genOutputR; 
      endmethod


      method Bool getGenOutputL;
        return leftGenOutput;
      endmethod

      method Bool getGenOutputR;
        return rightGenOutput;
      endmethod

      method RN_DBRS_SubMode getModeL;
        return leftMode;
      endmethod

      method RN_DBRS_SubMode getModeR;
        return rightMode;
      endmethod
    endinterface;
    
endmodule
