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

import DataTypes::*;
import MN_Types::*;

interface MN_MultiplierSwitch_NIC_ControlPorts;
  method Action putIptSelect(MS_IptSelect iptsel_signal);
  method Action putFwdSelect(MS_FwdSelect fwdsel_signal);
  method Action putArgSelect(MS_ArgSelect argsel_signal);
endinterface

interface MN_MultiplierSwitch_NIC_DataPorts;
  method Action putIptData(Data newInputData);
  method Action putFwdData(Maybe#(Data) newFwdData);
  method Action putPSum(Data newPSum);

  method Maybe#(Data) getStationaryArgument;
  method ActionValue#(Maybe#(Data)) getDynamicArgument;  

  method ActionValue#(Data) getPSum;
  method ActionValue#(Maybe#(Data)) getFwdData;

endinterface

interface MN_MultiplierSwitch_NIC;
  interface MN_MultiplierSwitch_NIC_ControlPorts controlPorts;
  interface MN_MultiplierSwitch_NIC_DataPorts dataPorts;
endinterface

(* synthesize *)
module mkMN_MultiplierSwitch_NIC(MN_MultiplierSwitch_NIC);
  /* Control singal wires */
  RWire#(MS_IptSelect) iptSelSignal <- mkRWire;
  RWire#(MS_FwdSelect) fwdSelSignal <- mkRWire;
  RWire#(MS_ArgSelect) argSelSignal <- mkRWire;
/*
  RWire#(Bool) streamDataDeq <- mkRWire;
  RWire#(Bool) stationaryDataDeq <- mkRWire;
  RWire#(Bool) fwdDataDeq <- mkRWire;
*/
  
  /* Buffers */
  Reg#(Maybe#(Data)) stationaryData <- mkReg(Invalid); 
  Fifo#(MS_IngressFifoDepth, Data) streamData <- mkPipelineFifo;
  Fifo#(MS_FwdFifoDepth, Data) fwdData <- mkPipelineFifo;
  Fifo#(MS_PSumFifoDepth, Data) pSumData <- mkBypassFifo;

  interface controlPorts = 
    interface MN_MultiplierSwitch_NIC_ControlPorts
      method Action putIptSelect(MS_IptSelect iptsel_signal);
        iptSelSignal.wset(iptsel_signal);
      endmethod

      method Action putFwdSelect(MS_FwdSelect fwdsel_signal);
        fwdSelSignal.wset(fwdsel_signal);
      endmethod

      method Action putArgSelect(MS_ArgSelect argsel_signal);
        argSelSignal.wset(argsel_signal);
      endmethod
    endinterface;

  interface dataPorts = 
    interface MN_MultiplierSwitch_NIC_DataPorts
      method Action putIptData(Data newInputData) if(isValid(iptSelSignal.wget()));
        let iptSel = validValue(iptSelSignal.wget());
        `ifdef DEBUG_MN_MS_NIC
        $display("[MN_MS_NIC] IptSel: %b", iptSel);
        `endif
        case(iptSel)
          ms_iptStationary: begin
          `ifdef DEBUG_MN_MS_NIC
            $display("[MN_MS_NIC] Received statioanry data");
          `endif
            stationaryData <=  Valid(newInputData);
          end
          ms_iptStream: begin
          `ifdef DEBUG_MN_MS_NIC        
            $display("[MN_MS_NIC] Received streamed data");
          `endif
            streamData.enq(newInputData);
          end
          default:
            noAction();
        endcase

      endmethod

      method Action putFwdData(Maybe#(Data) newFwdData) if(isValid(fwdSelSignal.wget()));
        if(isValid(newFwdData)) begin
          fwdData.enq(validValue(newFwdData));
        end
      endmethod

      method Action putPSum(Data newPSum);
        `ifdef DEBUG_MN_MS_NIC
          $display("[MN_MS_NIC]: Received a pSum");
        `endif
        pSumData.enq(newPSum);
      endmethod
 
      method Maybe#(Data) getStationaryArgument;
        return stationaryData;
      endmethod

      method ActionValue#(Maybe#(Data)) getDynamicArgument if(isValid(argSelSignal.wget()));
        let argSel = validValue(argSelSignal.wget());
        let ret = ?;

        case(argSel)
          ms_argInput: begin
            streamData.deq;
            ret = Valid(streamData.first);
          end
          ms_argFwd: begin
            fwdData.deq;
            ret = Valid(fwdData.first);
          end
          default: begin
            ret = Invalid;
          end
        endcase

        return ret;
      endmethod

      method ActionValue#(Data) getPSum;
        `ifdef DEBUG_MN_MS_NIC
          $display("[MN_MS_NIC]: Sending out a pSum");
        `endif

        pSumData.deq;
        return pSumData.first;
      endmethod

      method ActionValue#(Maybe#(Data)) getFwdData if(isValid(fwdSelSignal.wget()));
        let fwdSel = validValue(fwdSelSignal.wget());
        let ret = ?;

        case(fwdSel)
          ms_fwdInput:
            ret = Valid(streamData.first);
          ms_fwdFwd:
            ret = Valid(fwdData.first);

          default:
            ret = Invalid;
        endcase

        return ret;
      endmethod

    endinterface;


endmodule
