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

import AcceleratorConfig::*;
import DataTypes::*;
import RN_Types::*;
import GenericInterface::*;

import RN_SglReductionSwitch_Controller::*;
import RN_SglReductionSwitch_IngressNIC::*;
import RN_SglReductionSwitch_EgressNIC::*;
import RN_SglReductionSwitch_Datapath::*;

interface RN_SglReductionSwitch_ControlPorts;
  `ifdef DEBUG_RN
    method Action initialize(RN_NodeID newNodeID);
  `endif
   method Action putConfig(RN_SglRSConfig newConfig);
endinterface

interface RN_SglReductionSwitch;
  interface RN_SglReductionSwitch_ControlPorts controlPorts;
  interface Vector#(2, GI_InputDataPorts) inputDataPorts;
  interface GI_OutputDataPorts outputDataPorts;
  interface GI_OutputDataPorts resultsDataPorts;  
endinterface

(* synthesize *)
module mkRN_SglReductionSwitch(RN_SglReductionSwitch);
  `ifdef DEBUG_RN
  Reg#(Bool) inited <- mkReg(False);
  Reg#(RN_NodeID) nodeID <- mkReg(0);
  `endif

  RN_SglReductionSwitch_Controller controller <- mkRN_SglReductionSwitch_Controller;
  RN_SglReductionSwitch_IngressNIC ingressNIC <- mkRN_SglReductionSwitch_IngressNIC;
  RN_SglReductionSwitch_EgressNIC egressNIC <- mkRN_SglReductionSwitch_EgressNIC;

  RN_SglReductionSwitch_Datapath datapath <- mkRN_SglReductionSwitch_Datapath;

  mkConnection(controller.controlPorts.getMode, datapath.controlPorts.putMode);
  mkConnection(controller.controlPorts.getGenOutput, egressNIC.controlPorts.putGenOutput);

  for(Integer prt = 0; prt < 2; prt = prt+1) begin
    mkConnection(ingressNIC.dataPorts[prt].getData,
                  datapath.inputDataPorts[prt].putData);
  end

  mkConnection(datapath.outputDataPorts.getData,
                 egressNIC.dataPorts.putData);

  Vector#(2, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0; inPrt < 2; inPrt = inPrt + 1) begin
    inputDataPortsDef[inPrt] =
      interface GI_InputDataPorts
        method Action putData(Data data);
          `ifdef DEBUG_RN
          `ifdef DEBUG_RN_SGRS
          $display("[RN_SGRS] Single Reduction Switch %d, received a data at port %d", nodeID, inPrt);
          `endif
          `endif    
          ingressNIC.dataPorts[inPrt].putData(data);          
        endmethod
      endinterface;
  end

  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = 
    interface GI_OutputDataPorts
      method ActionValue#(Data) getData;
          `ifdef DEBUG_RN
          `ifdef DEBUG_RN_SGRS
          $display("[RN_SGRS] Single Reduction Switch %d, sent a data", nodeID);
          `endif
          `endif    

        let ret <- egressNIC.dataPorts.getData;
        return ret;
      endmethod
    endinterface;

  interface resultsDataPorts = 
    interface GI_OutputDataPorts
      method ActionValue#(Data) getData;
        `ifdef DEBUG_RN      
        `ifdef DEBUG_RN_SGRS
          $display("[RN_SGRS] Single Reduction Switch %d, sent a result", nodeID);
        `endif
        `endif
        let ret <- egressNIC.resultsDataPorts.getData;
        return ret;
      endmethod
    endinterface;

  interface controlPorts =
    interface RN_SglReductionSwitch_ControlPorts
      `ifdef DEBUG_RN
        method Action initialize(RN_NodeID newNodeID);
          nodeID <= newNodeID;
        endmethod
      `endif
      
      method Action putConfig(RN_SglRSConfig newConfig);
        controller.controlPorts.putConfig(newConfig);
      endmethod
    endinterface;

endmodule