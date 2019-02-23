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

import Fifo::*;
import RWire::*;

import MN_Types::*;

interface MN_MultiplierSwitch_Controller_ControlPorts;
  method Action putNewConfig(MS_Config newConfig);
  method Action putPSumGenNotice;

  method  MS_IptSelect getIptSelect;
  method  MS_FwdSelect getFwdSelect;
  method  MS_ArgSelect getArgSelect;

  method Bool getDoCompute;
endinterface

interface MN_MultiplierSwitch_Controller;
  interface MN_MultiplierSwitch_Controller_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkMN_MultiplierSwitch_Controller(MN_MultiplierSwitch_Controller);

  Fifo#(1, MS_State) incomingNextState <- mkBypassFifo;
  Fifo#(1, MS_PSumCount) incomingNextPSumCount <- mkBypassFifo;

  Reg#(MS_State) stateReg <- mkReg(ms_idle);
  Reg#(MS_PSumCount) pSumCounter <- mkReg(0);

  RWire#(Bool) pSumGenNotification <- mkRWire;

  function MS_IptSelect computeIptSelect;
    let ret = ?;

    case(stateReg)
      ms_idle:
        ret = ms_iptNothing;
      ms_initSteadyVal:
        ret = ms_iptStationary;
      ms_runLEdgeFirst:
        ret = ms_iptStream;
      ms_runLEdge:
        ret = ms_iptStream;
      ms_runMiddleFirst:
        ret = ms_iptStream;
      ms_runMiddle:
        ret = ms_iptNothing;
      ms_runREdgeFirst:
        ret = ms_iptStream;
      ms_runREdge:
        ret = ms_iptNothing;
      default:
        ret = ms_iptNothing;
    endcase

    return ret;
  endfunction

  function MS_FwdSelect computeFwdSelect;
    let ret = ?;

    case(stateReg)
      ms_idle:
        ret = ms_fwdNothing;
      ms_initSteadyVal:
        ret = ms_fwdNothing;      
      ms_runLEdgeFirst:
        ret = ms_fwdInput;      
      ms_runLEdge:
        ret = ms_fwdInput;      
      ms_runMiddleFirst:
        ret = ms_fwdInput;
      ms_runMiddle:
        ret = ms_fwdFwd;
      ms_runREdgeFirst:
        ret = ms_fwdNothing;      
      ms_runREdge:
        ret = ms_fwdNothing;      
      default:
        ret = ms_fwdNothing;
    endcase

    return ret;

  endfunction

  function MS_ArgSelect computeArgSelect;
    let ret = ?;

    case(stateReg)
      ms_idle:
        ret = ms_argNothing;
      ms_initSteadyVal:
        ret = ms_argNothing;
      ms_runLEdgeFirst:
        ret = ms_argInput;
      ms_runLEdge:
        ret = ms_argInput;
      ms_runMiddleFirst:
        ret = ms_argInput;
      ms_runMiddle:
        ret = ms_argFwd;
      ms_runREdgeFirst:
        ret = ms_argInput;
      ms_runREdge:
        ret = ms_argFwd;
      default:
        ret = ms_argFwd;
    endcase

    return ret;
  endfunction

  function Bool computeDoCompute;
    let ret = ?;

    case(stateReg)
      ms_idle:
        ret = False;
      ms_initSteadyVal:
        ret = False;
      ms_runLEdgeFirst:
        ret = True;
      ms_runLEdge:
        ret = True;
      ms_runMiddleFirst:
        ret = True;
      ms_runMiddle:
        ret = True;
      ms_runREdgeFirst:
        ret = True;
      ms_runREdge:
        ret = True;
      default:
        ret = False;
    endcase

    return ret;
  endfunction

  rule updateState(pSumCounter == 0);
    let nextState = ?;
    let nextPSumCount = ?;

    if(incomingNextState.notEmpty && incomingNextPSumCount.notEmpty) begin
      incomingNextState.deq;
      incomingNextPSumCount.deq;
      nextState = incomingNextState.first;
      nextPSumCount = incomingNextPSumCount.first;
      `ifdef DEBUG_MN_MS_CONTROLLER
      $display("[MN_MS_Controller]State update to :%b", nextState);      
      `endif
    end
    else begin
      nextState = stateReg;
      nextPSumCount = pSumCounter;
    end

    stateReg <= nextState;
    pSumCounter <= nextPSumCount;
  endrule

  // Transit from the first exceptional state to steady states
  rule transitState(pSumCounter != 0);
    let nextState = stateReg;

//    if(isValid(pSumGenNotification.wget())) begin 
      case(stateReg)
        ms_runLEdgeFirst:
          nextState = ms_runLEdge;
        ms_runMiddleFirst:
          nextState = ms_runMiddle;
        ms_runREdgeFirst:
          nextState = ms_runREdge;
       default:
         nextState = stateReg;
     endcase
//   end

    stateReg <= nextState;
  endrule

  interface controlPorts =
    interface MN_MultiplierSwitch_Controller_ControlPorts
      method Action putNewConfig(MS_Config newConfig);
        incomingNextState.enq(newConfig.state);
        incomingNextPSumCount.enq(newConfig.psumCount);
      endmethod

      method Action putPSumGenNotice if(pSumCounter != 0);
        pSumCounter <= pSumCounter -1;
        pSumGenNotification.wset(True);
      endmethod

      method  MS_IptSelect getIptSelect = computeIptSelect;
      method  MS_FwdSelect getFwdSelect = computeFwdSelect;
      method  MS_ArgSelect getArgSelect = computeArgSelect;
      method Bool getDoCompute = computeDoCompute;

    endinterface;

endmodule
