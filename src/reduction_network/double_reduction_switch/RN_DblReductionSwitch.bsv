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
import GenericInterface::*;
import RN_Types::*;

import RN_DblReductionSwitch_Controller::*;
import RN_DblReductionSwitch_IngressNIC::*;
import RN_DblReductionSwitch_EgressNIC::*;
import RN_DblReductionSwitch_Datapath::*;

interface RN_DblReductionSwitch_ControlPorts;
  `ifdef DEBUG_RN
    method Action initialize(RN_NodeID newNodeID);
  `endif
  method Action putConfig(RN_DblRSConfig newConfig);  
endinterface

interface RN_DblReductionSwitch;
  interface RN_DblReductionSwitch_ControlPorts controlPorts;
  interface Vector#(4, GI_InputDataPorts) inputDataPorts;
  interface Vector#(2, GI_OutputDataPorts) outputDataPorts;
  interface Vector#(2, GI_OutputDataPorts) resultsDataPorts;
endinterface

(* synthesize *)
module mkRN_DblReductionSwitch(RN_DblReductionSwitch);
  `ifdef DEBUG_RN
  Reg#(RN_NodeID) nodeID <- mkReg(0);
  `endif

  RN_DblReductionSwitch_Controller controller <- mkRN_DblReductionSwitch_Controller;
  RN_DblReductionSwitch_IngressNIC ingressNIC <- mkRN_DblReductionSwitch_IngressNIC;
  RN_DblReductionSwitch_EgressNIC egressNIC <- mkRN_DblReductionSwitch_EgressNIC;

  RN_DblReductionSwitch_Datapath datapath <- mkRN_DblReductionSwitch_Datapath;

  mkConnection(controller.controlPorts.getModeL(), datapath.controlPorts.putModeL());
  mkConnection(controller.controlPorts.getModeR(), datapath.controlPorts.putModeR());

  mkConnection(controller.controlPorts.getGenOutputL, egressNIC.controlPorts.putGenOutputL);
  mkConnection(controller.controlPorts.getGenOutputR, egressNIC.controlPorts.putGenOutputR);

  for(Integer prt = 0; prt < 4; prt = prt+1) begin
    mkConnection(ingressNIC.dataPorts[prt].getData,
                  datapath.inputDataPorts[prt].putData);
  end

  for(Integer prt = 0; prt < 2; prt = prt+1) begin
    mkConnection(datapath.outputDataPorts[prt].getData,
                   egressNIC.dataPorts[prt].putData);
  end

  Vector#(4, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0; inPrt < 4; inPrt = inPrt + 1) begin
    inputDataPortsDef[inPrt] =
      interface GI_InputDataPorts
        method Action putData(Data data);
          `ifdef DEBUG_RN
          `ifdef DEBUG_RN_DBRS
          $display("[RN_DBRS] Double Switch %d, received a data at port %d", nodeID, inPrt);
          `endif
          `endif    
          ingressNIC.dataPorts[inPrt].putData(data);    
        endmethod
      endinterface;
  end

  Vector#(2, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer outPrt = 0; outPrt < 2; outPrt = outPrt + 1) begin
    outputDataPortsDef[outPrt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          `ifdef DEBUG_RN
          `ifdef DEBUG_RN_DBRS
          $display("[RN_DBRS] Double Switch %d, outputed a data to port %d", nodeID, outPrt);
          `endif
          `endif    
          let ret <- egressNIC.dataPorts[outPrt].getData;
          return ret;
        endmethod
      endinterface;
  end

  Vector#(2, GI_OutputDataPorts) resultsDataPortsDef;
  for(Integer outPrt = 0; outPrt < 2; outPrt = outPrt + 1) begin
    resultsDataPortsDef[outPrt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;

          `ifdef DEBUG_RN
          `ifdef DEBUG_RN_DBRS
          $display("[RN_DBRS] Double Switch %d, outputed a result to port %d", nodeID, outPrt);
          `endif
          `endif    

          let ret <- egressNIC.resultsDataPorts[outPrt].getData;
          return ret;
        endmethod
      endinterface;
  end

  interface controlPorts =
    interface RN_DblReductionSwitch_ControlPorts
      `ifdef DEBUG_RN
        method Action initialize(RN_NodeID newNodeID);
          controller.controlPorts.initialize(newNodeID);
          datapath.controlPorts.initialize(newNodeID);
          nodeID <= newNodeID;
        endmethod
      `endif

      method Action putConfig(RN_DblRSConfig newConfig);
        controller.controlPorts.putConfig(newConfig);
        `ifdef DEBUG_RN
        `ifdef DEBUG_RN_DBRS
        $display("[RN_DBRS] Double Switch %d, received a config mode:%b, genOutputL:%b, genOutputR: %b", nodeID, newConfig.mode, newConfig.genOutputL, newConfig.genOutputR);
        `endif
        `endif    
      endmethod
    endinterface;

  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = outputDataPortsDef;
  interface resultsDataPorts = resultsDataPortsDef;

endmodule