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

import Connectable::*;

import DataTypes::*;
import DN_Types::*;

import DN_DistributionSwitch_Controller::*;
import DN_DistributionSwitch_NIC::*;

interface DN_DistributionSwitch_DataPorts;
  method Action putData(Data newIptData);
  method Data getDataL;
  method Data getDataR;  
endinterface

interface DN_DistributionSwitch_ControlPorts;
  `ifdef DEBUG_DN
  method Action putNodeID(DN_NodeID nodeID);
  `endif
  method Action putNewConfig(DS_Config newConfig);
endinterface

interface DN_DistributionSwitch;
  interface DN_DistributionSwitch_DataPorts dataPorts;  
  interface DN_DistributionSwitch_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkDN_DistributionSwitch(DN_DistributionSwitch);
  `ifdef DEBUG_DN
  Reg#(DN_NodeID) nodeID <- mkReg(0);
  `endif
  DN_DistributionSwitch_Controller controller <- mkDN_DistributionSwitch_Controller;
  DN_DistributionSwitch_NIC nic <- mkDN_DistributionSwitch_NIC;

  mkConnection(controller.controlPorts.getRouteLeft, nic.controlPorts.putRouteLeft);
  mkConnection(controller.controlPorts.getRouteRight, nic.controlPorts.putRouteRight);

  interface dataPorts = 
    interface DN_DistributionSwitch_DataPorts
      method Action putData(Data newIptData);
        `ifdef DEBUG_DN
        `ifdef DEBUG_DN_DS
          $display("[DN_DS%d] received a data",nodeID);
        `endif
        `endif
        nic.dataPorts.putData(newIptData);
      endmethod

      method Data getDataL;
        return nic.dataPorts.getDataL();
      endmethod

      method Data getDataR;
        return nic.dataPorts.getDataR();
      endmethod
    endinterface;

  interface controlPorts = 
    interface DN_DistributionSwitch_ControlPorts;
      `ifdef DEBUG_DN
        method Action putNodeID(DN_NodeID newNodeID);
          nodeID <= newNodeID;
        endmethod
      `endif
 

      method Action putNewConfig(DS_Config newConfig);
        `ifdef DEBUG_DN
        `ifdef DEBUG_DN_DS
          $display("[DN_DS%d] received a configuration %b",nodeID, newConfig);
        `endif
        `endif
        controller.controlPorts.putNewConfig(newConfig);
      endmethod

    endinterface;

endmodule