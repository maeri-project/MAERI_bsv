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

import RWire::*;

import DataTypes::*;
import DN_Types::*;

interface DN_DistributionSwitch_NIC_ControlPorts;
  method Action putRouteLeft(Bool routeLeft);
  method Action putRouteRight(Bool routeRight);
endinterface

interface DN_DistributionSwitch_NIC_DataPorts;
  method Action putData(Data newIptData);
  method Data getDataL;
  method Data getDataR;  
endinterface

interface DN_DistributionSwitch_NIC;
  interface DN_DistributionSwitch_NIC_DataPorts dataPorts;
  interface DN_DistributionSwitch_NIC_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkDN_DistributionSwitch_NIC(DN_DistributionSwitch_NIC);
  RWire#(Data) iptData <- mkRWire;
  RWire#(Data) outDataL <- mkRWire;
  RWire#(Data) outDataR <- mkRWire;

  RWire#(Bool) routeL <- mkRWire;
  RWire#(Bool) routeR <- mkRWire;

  rule selectOutDataL(isValid(iptData.wget()) && isValid(routeL.wget()));
    if(validValue(routeL.wget()) == True) begin
      outDataL.wset(validValue(iptData.wget()));
    end
  endrule

  rule selectOutDataR(isValid(iptData.wget()) && isValid(routeR.wget()));
    if(validValue(routeR.wget()) == True) begin
      outDataR.wset(validValue(iptData.wget()));
    end
  endrule

  interface dataPorts = 
    interface DN_DistributionSwitch_NIC_DataPorts
      method Action putData(Data newIptData);
        iptData.wset(newIptData);
      endmethod

      method Data getDataL if(isValid(outDataL.wget()));
        return validValue(outDataL.wget());
      endmethod

      method Data getDataR if(isValid(outDataR.wget()));  
        return validValue(outDataR.wget());
      endmethod
    endinterface;

  interface controlPorts = 
    interface DN_DistributionSwitch_NIC_ControlPorts
      method Action putRouteLeft(Bool routeLeft);
        routeL.wset(routeLeft);
      endmethod

      method Action putRouteRight(Bool routeRight);
        routeR.wset(routeRight);
      endmethod
    endinterface;

endmodule