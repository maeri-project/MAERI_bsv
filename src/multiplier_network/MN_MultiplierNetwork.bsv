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
import DataTypes::*;
import MN_Types::*;
import SU_Types::*;
import GenericInterface::*;

import MN_MultiplierSwitch::*;

interface MN_MultiplierNetwork_ControlPorts;
  method Action putConfig(MN_Config newConfig, StatData numActualActiveMultSwitches);
endinterface

interface MN_MultiplierNetwork;
  interface Vector#(NumMultSwitches, GI_DataPorts) dataPorts;
  interface MN_MultiplierNetwork_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkMN_MultiplierNetwork(MN_MultiplierNetwork);
  Vector#(NumMultSwitches, MN_MultiplierSwitch) multSwitches <- replicateM(mkMN_MultiplierSwitch);

  /* Forward links */
  for(Integer sw = 0; sw < valueOf(NumMultSwitches) -1; sw = sw+1) begin
    mkConnection(multSwitches[sw].dataPorts.getFwdData, multSwitches[sw+1].dataPorts.putFwdData);
  end

  Vector#(NumMultSwitches, GI_DataPorts) dataPortsDef;
  for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
    dataPortsDef[sw] = 
      interface GI_DataPorts
        method Action putData(Data data);
          multSwitches[sw].dataPorts.putIptData(data);
        endmethod

        method ActionValue#(Data) getData;
          let pSum <- multSwitches[sw].dataPorts.getPSum;
          return pSum;
        endmethod
      endinterface;
  end
  interface dataPorts = dataPortsDef;

  interface controlPorts = 
    interface MN_MultiplierNetwork_ControlPorts
      method Action putConfig(MN_Config newConfig, StatData numActualActiveMultSwitches);
        for(Integer sw = 0; sw < valueOf(NumMultSwitches); sw = sw +1) begin
          if(fromInteger(sw) < numActualActiveMultSwitches) begin
            multSwitches[sw].controlPorts.putNewConfig(newConfig[sw]);
          end          
        end
      endmethod
    endinterface;

endmodule
