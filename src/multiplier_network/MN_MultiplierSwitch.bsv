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

import DataTypes::*;
import Connectable::*;

`ifdef INT16
import INT16::*;
import INT16_Multiplier::*;
`endif
import MN_Types::*;

import MN_MultiplierSwitch_NIC::*;
import MN_MultiplierSwitch_Controller::*;

interface MN_MultiplierSwitch_DataPorts;
  method Action putIptData(Data newIptData);
  method Action putFwdData(Maybe#(Data) newFwdData);

  method ActionValue#(Maybe#(Data)) getFwdData;
  method ActionValue#(Data) getPSum;
endinterface

interface MN_MultiplierSwitch_ControlPorts;
  method Action putNewConfig(MS_Config newConfig);
endinterface

interface MN_MultiplierSwitch;
  interface MN_MultiplierSwitch_DataPorts dataPorts;
  interface MN_MultiplierSwitch_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkMN_MultiplierSwitch(MN_MultiplierSwitch);

  MN_MultiplierSwitch_NIC nic <- mkMN_MultiplierSwitch_NIC;
  MN_MultiplierSwitch_Controller controller <- mkMN_MultiplierSwitch_Controller;

`ifdef INT16
  SC_INT16ALU alu <- mkSC_INT16Multiplier;
`endif

  mkConnection(controller.controlPorts.getIptSelect , nic.controlPorts.putIptSelect);
  mkConnection(controller.controlPorts.getFwdSelect , nic.controlPorts.putFwdSelect);
  mkConnection(controller.controlPorts.getArgSelect , nic.controlPorts.putArgSelect);

  rule doCompute(controller.controlPorts.getDoCompute() == True);
    let argA = nic.dataPorts.getStationaryArgument();
    let argB <- nic.dataPorts.getDynamicArgument();

    if(isValid(argA) && isValid(argB)) begin
      let argAVal = validValue(argA);
      let argBVal = validValue(argB);
      let res = alu.getRes(argAVal, argBVal);
      nic.dataPorts.putPSum(res);
    end
  endrule

  interface dataPorts =
    interface MN_MultiplierSwitch_DataPorts
      method Action putIptData(Data newIptData);
        nic.dataPorts.putIptData(newIptData);
      endmethod

      method Action putFwdData(Maybe#(Data) newFwdData);
        nic.dataPorts.putFwdData(newFwdData);
      endmethod

      method ActionValue#(Maybe#(Data)) getFwdData;
        let fwdData <- nic.dataPorts.getFwdData;
        return fwdData;
      endmethod

      method ActionValue#(Data) getPSum;
        controller.controlPorts.putPSumGenNotice;
        let res <- nic.dataPorts.getPSum;
        return res;
      endmethod
    endinterface;

  interface controlPorts = 
    interface MN_MultiplierSwitch_ControlPorts
      method Action putNewConfig(MS_Config newConfig);
        controller.controlPorts.putNewConfig(newConfig);
      endmethod
    endinterface;
  
endmodule
