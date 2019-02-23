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
import Connectable::*;

import AcceleratorConfig::*;
import GenericInterface::*;
import DataTypes::*;
import DN_Types::*;
import MN_Types::*;
import RN_Types::*;
import SU_Types::*;

import DN_DistributionNetwork::*;
import MN_MultiplierNetwork::*;
import RN_ReductionNetwork::*;


interface DN_TopControlPorts;
  method Action putConfig(DN_SubTreeDestBits newConfig);
endinterface 


interface MAERI_Accelerator_ControlPorts;
  method Bool isReadyForNextConfig;
  interface MN_MultiplierNetwork_ControlPorts mnControlPorts;
  interface RN_ReductionNetwork_ControlPorts rnControlPorts;
  interface Vector#(DistributionBandwidth, DN_TopControlPorts) dnControlPorts;
endinterface


interface MAERI_Accelerator;
  interface MAERI_Accelerator_ControlPorts controlPorts;
  interface Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPorts;
  interface Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPorts;
endinterface

(* synthesize *)
module mkMAERI_Accelerator(MAERI_Accelerator);
  /* Submodules */
  DN_DistributionNetwork dn <- mkDN_DistributionNetwork;
  MN_MultiplierNetwork mn <- mkMN_MultiplierNetwork;
  RN_ReductionNetwork rn <- mkRN_ReductionNetwork;

  /* Interconnect DN and MN */
  for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID +1) begin
    mkConnection(dn.outputDataPorts[multSwID].getData, mn.dataPorts[multSwID].putData);
  end

  /* Interconnect MN and RN */
  for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID +1) begin
    mkConnection(mn.dataPorts[multSwID].getData, rn.inputDataPorts[multSwID].putData);
  end


  /* Interfaces */
  Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0; inPrt < valueOf(DistributionBandwidth); inPrt = inPrt +1) begin
    inputDataPortsDef[inPrt] = 
      interface GI_InputDataPorts
        method Action putData(Data data);
          dn.inputDataPorts[inPrt].putData(data);
        endmethod
      endinterface;
  end

  Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer outPrt = 0; outPrt < valueOf(CollectionBandwidth); outPrt = outPrt +1) begin
    outputDataPortsDef[outPrt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          let ret <- rn.outputDataPorts[outPrt].getData;
          return ret;
        endmethod
      endinterface;

  end

  Vector#(DistributionBandwidth, DN_TopControlPorts) dnControlPortsDef;
  for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt + 1) begin
    dnControlPortsDef[prt] =
      interface DN_TopControlPorts
        method Action putConfig(DN_SubTreeDestBits newConfig);
          if(newConfig != dn_topSubtree_nullConfig) begin
            dn.controlPorts[prt].putConfig(newConfig); 
          end
        endmethod
      endinterface;
  end

  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = outputDataPortsDef;

  interface controlPorts = 
    interface MAERI_Accelerator_ControlPorts
      method Bool isReadyForNextConfig;
        return dn.isEmpty;
      endmethod
      interface mnControlPorts = 
        interface MN_MultiplierNetwork_ControlPorts
          method Action putConfig(MN_Config newConfig, StatData numActualActiveMultSwitches);
            mn.controlPorts.putConfig(newConfig, numActualActiveMultSwitches);
          endmethod
        endinterface;

      interface rnControlPorts = 
        interface RN_ReductionNetwork_ControlPorts
          method Action putConfig(RN_Config newConfig);
            rn.controlPorts.putConfig(newConfig);
          endmethod
        endinterface;

      interface dnControlPorts = dnControlPortsDef;

    endinterface;

endmodule

