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


import AcceleratorConfig::*;
import DataTypes::*;
import GenericInterface::*;
import RN_Types::*;


`ifdef INT16
import INT16::*;
import INT16_Adder::*;
`endif

interface RN_SglReductionSwitch_Datapath_ControlPorts;
  method Action putMode(RN_SGRS_Mode mode);
endinterface

interface RN_SglReductionSwitch_Datapath;
  interface Vector#(2, GI_InputDataPorts) inputDataPorts;
  interface GI_OutputDataPorts outputDataPorts;

  interface RN_SglReductionSwitch_Datapath_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkRN_SglReductionSwitch_Datapath(RN_SglReductionSwitch_Datapath);

  /* I/O Fifo/wires */
  Fifo#(1, Data) fifo_inputL <- mkBypassFifo;
  Fifo#(1, Data) fifo_inputR <- mkBypassFifo;

  Fifo#(1, Data) fifo_out <- mkBypassFifo;

  RWire#(RN_SGRS_Mode) wire_mode <- mkRWire;

  let mode = validValue(wire_mode.wget());

  /* Submodules */
  `ifdef INT16
  SC_INT16ALU adder <- mkSC_INT16Adder;
  `endif

  /* rules */

  rule doAddTwo(mode == rn_sgrs_mode_addTwo);
    let dataL = fifo_inputL.first;
    let dataR = fifo_inputR.first;
    fifo_inputL.deq;
    fifo_inputR.deq;

    let outData = adder.getRes(dataL, dataR);

    fifo_out.enq(outData);
  endrule

  rule doFlowLeft(mode == rn_sgrs_mode_flowLeft);
    let dataL = fifo_inputL.first;
    fifo_inputL.deq;

    let outData = dataL;
    
    fifo_out.enq(outData);
  endrule

  rule doFlowRight(mode == rn_sgrs_mode_flowRight);
    let dataR = fifo_inputR.first;
    fifo_inputR.deq;   

    let outData = dataR;

    fifo_out.enq(outData);
  endrule

  Vector#(2, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0 ; inPrt < 2; inPrt = inPrt+1) begin
    inputDataPortsDef[inPrt] =
      interface GI_InputDataPorts
        method Action putData(Data data);
          if(inPrt == 0) begin
            fifo_inputL.enq(data);
          end
          else begin
            fifo_inputR.enq(data);
          end
        endmethod
      endinterface;
  end

  interface inputDataPorts = inputDataPortsDef;

  interface outputDataPorts = 
    interface GI_OutputDataPorts
      method ActionValue#(Data) getData;
          fifo_out.deq;
          return fifo_out.first;
      endmethod
    endinterface;

  interface controlPorts = 
    interface RN_SglReductionSwitch_Datapath_ControlPorts
      method Action putMode(RN_DBRS_SubMode mode);
        wire_mode.wset(mode);
      endmethod
    endinterface;


endmodule
