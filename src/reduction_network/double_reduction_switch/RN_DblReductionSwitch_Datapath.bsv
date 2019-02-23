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
import CReg::*;

import AcceleratorConfig::*;
import DataTypes::*;
import GenericInterface::*;
import RN_Types::*;

`ifdef INT16
import INT16::*;
import INT16_Adder::*;
`endif

interface RN_DblReductionSwitch_Datapath_ControlPorts;
  `ifdef DEBUG_RN
    method Action initialize(RN_NodeID newNodeID);
  `endif
  method Action putModeL(RN_DBRS_SubMode modeL);
  method Action putModeR(RN_DBRS_SubMode modeR);
endinterface


interface RN_DblReductionSwitch_Datapath;
  interface Vector#(4, GI_InputDataPorts) inputDataPorts;
  interface Vector#(2, GI_OutputDataPorts) outputDataPorts;

  interface RN_DblReductionSwitch_Datapath_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkRN_DblReductionSwitch_Datapath(RN_DblReductionSwitch_Datapath);
  `ifdef DEBUG_RN
  Reg#(RN_NodeID) nodeID <- mkReg(0);
  `endif


  /* I/O Fifo/wires */
  Fifo#(1, Data) fifo_inputLL <- mkBypassFifo;
  Fifo#(1, Data) fifo_inputLR <- mkBypassFifo;
  Fifo#(1, Data) fifo_inputRL <- mkBypassFifo;
  Fifo#(1, Data) fifo_inputRR <- mkBypassFifo;

  CReg#(4, Bool) validLL <- mkCReg(False);
  CReg#(4, Bool) validLR <- mkCReg(False);  
  CReg#(4, Bool) validRL <- mkCReg(False);  
  CReg#(4, Bool) validRR <- mkCReg(False);  

  Fifo#(1, Data) fifo_outL <- mkBypassFifo;
  Fifo#(1, Data) fifo_outR <- mkBypassFifo;

  RWire#(RN_DBRS_SubMode) wire_modeL <- mkRWire;
  RWire#(RN_DBRS_SubMode) wire_modeR <- mkRWire;

  let modeL = validValue(wire_modeL.wget());
  let modeR = validValue(wire_modeR.wget());

  /* Submodules */
  `ifdef INT16
  Vector#(4, SC_INT16ALU) adders <- replicateM(mkSC_INT16Adder);
  `endif

  /* rules */
  rule doLeftThreeSum(modeL == rn_dbrs_submode_addThree && (modeR == rn_dbrs_submode_addOne || modeR == rn_dbrs_submode_idle));
    if(fifo_inputLL.notEmpty && fifo_inputLR.notEmpty && fifo_inputRL.notEmpty) begin
      let val_LL = fifo_inputLL.first;
      let val_LR = fifo_inputLR.first;
      let val_RL = fifo_inputRL.first;

      fifo_inputLL.deq;
      fifo_inputLR.deq;
      fifo_inputRL.deq;

      let intermediate_res = adders[0].getRes(val_LL, val_LR);
      let outDataL = adders[1].getRes(intermediate_res, val_RL);
      fifo_outL.enq(outDataL);
    end
  endrule

  rule doLeftTwoSum(modeL == rn_dbrs_submode_addTwo && modeR != rn_dbrs_submode_addThree);
    if(fifo_inputLL.notEmpty && fifo_inputLR.notEmpty) begin
      let val_LL = fifo_inputLL.first;
      let val_LR = fifo_inputLR.first;
      fifo_inputLL.deq;
      fifo_inputLR.deq;

      let outDataL = adders[0].getRes(val_LL, val_LR);

      fifo_outL.enq(outDataL);
    end

  endrule

  rule doLeftOneSum(modeL == rn_dbrs_submode_addOne); // (modeR != rn_dbrs_submode_addTwo && modeR != rn_dbrs_submode_addThree));
    if(fifo_inputLL.notEmpty) begin           
      let val_LL = fifo_inputLL.first;
      fifo_inputLL.deq;

      let outDataL = val_LL;

      fifo_outL.enq(outDataL);
    end
  endrule

  rule doRightThreeSum(modeR == rn_dbrs_submode_addThree && (modeL != rn_dbrs_submode_addThree || modeL != rn_dbrs_submode_addTwo));
    if(fifo_inputRL.notEmpty && fifo_inputRR.notEmpty && fifo_inputLR.notEmpty) begin      
      let val_RL = fifo_inputRL.first;
      let val_RR = fifo_inputRR.first;
      let val_LR = fifo_inputLR.first;
      fifo_inputRL.deq;
      fifo_inputRR.deq;
      fifo_inputLR.deq;

      let intermediate_res = adders[2].getRes(val_RL, val_RR);
      let outDataR = adders[3].getRes(intermediate_res, val_LR);

      fifo_outR.enq(outDataR);
    end
  endrule

  rule doRightTwoSum(modeR == rn_dbrs_submode_addTwo && (modeL != rn_dbrs_submode_addThree));
    if(fifo_inputRL.notEmpty && fifo_inputRR.notEmpty) begin
      let val_RL = fifo_inputRL.first;
      let val_RR = fifo_inputRR.first;
      fifo_inputRL.deq;
      fifo_inputRR.deq;

      let outDataR = adders[2].getRes(val_RL, val_RR);

      fifo_outR.enq(outDataR);
    end
  endrule

  rule doRgihtOneSum(modeR == rn_dbrs_submode_addOne); // && (modeL == rn_dbrs_submode_idle || modeL == rn_dbrs_submode_addOne));
    if(fifo_inputRR.notEmpty) begin      
      let val_RR = fifo_inputRR.first;
      fifo_inputRR.deq;

      let outDataR = val_RR;

      fifo_outR.enq(outDataR);
    end
  endrule

  Vector#(4, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0 ; inPrt < 4; inPrt = inPrt+1) begin
    inputDataPortsDef[inPrt] =
      interface GI_InputDataPorts
        method Action putData(Data data);
          if(inPrt == 0) begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9)  
                $display("DBRS %d enque LL", nodeID);
            `endif
            `endif
            fifo_inputLL.enq(data);
            validLL[0] <= True;
          end
          else if(inPrt == 1) begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9)           
               $display("DBRS %d enque LR", nodeID)   ;       
            `endif
            `endif
            fifo_inputLR.enq(data);
            validLR[0] <= True;            
          end
          else if(inPrt == 2) begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9)         
               $display("DBRS %d enque RL", nodeID)   ;
            `endif
            `endif
            fifo_inputRL.enq(data);
            validRL[0] <= True;            
          end
          else begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9)         
                $display("DBRS %d enque RR", nodeID)     ;     
            `endif
            `endif
            fifo_inputRR.enq(data);
            validRR[0] <= True;            
          end
        endmethod
      endinterface;
  end

  Vector#(2, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer outPrt = 0 ; outPrt < 2; outPrt = outPrt+1) begin
    outputDataPortsDef[outPrt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          if(outPrt == 0) begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9) 
                $display("DBRS %d outputs L", nodeID);
            `endif
            `endif
            fifo_outL.deq;
            return fifo_outL.first;
          end
          else begin
            `ifdef DEBUG_RN
            `ifdef DEBUG_RN_RS_DATAPATH
              if(nodeID == 9)           
                $display("DBRS %d outputs R", nodeID) ;         
            `endif
            `endif
            
            fifo_outR.deq;
            return fifo_outR.first;
          end
        endmethod
      endinterface;
  end

  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = outputDataPortsDef;

  interface controlPorts = 
    interface RN_DblReductionSwitch_Datapath_ControlPorts
    `ifdef DEBUG_RN
      method Action initialize(RN_NodeID newNodeID);
        nodeID <= newNodeID;
      endmethod
    `endif



      method Action putModeL(RN_DBRS_SubMode modeL);
        wire_modeL.wset(modeL);
      endmethod

      method Action putModeR(RN_DBRS_SubMode modeR);
        wire_modeR.wset(modeR);
      endmethod
    endinterface;

endmodule
