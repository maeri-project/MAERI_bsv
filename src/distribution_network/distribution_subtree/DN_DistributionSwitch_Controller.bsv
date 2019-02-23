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
import DN_Types::*;

interface DN_DistributionSwitch_Controller_DataPorts;
  method Action putNewConfig(DS_Config newConfig);

  method Bool getRouteLeft;
  method Bool getRouteRight;

endinterface

interface DN_DistributionSwitch_Controller;
  interface DN_DistributionSwitch_Controller_DataPorts controlPorts;
endinterface


(* synthesize *)
module mkDN_DistributionSwitch_Controller(DN_DistributionSwitch_Controller);
  Reg#(DS_State) stateReg <- mkReg(ds_idle);

  interface controlPorts =
    interface DN_DistributionSwitch_Controller_DataPorts
      method Action putNewConfig(DS_Config newConfig);
        stateReg <= newConfig;
      endmethod

      method Bool getRouteLeft;
        let ret = ?;
        case(stateReg)
          ds_left:
            ret = True;
          ds_right:
            ret = False;
          ds_both:
            ret = True;
          default: //ds_idle
            ret = False;
        endcase

        return ret;
      endmethod

      method Bool getRouteRight;
        let ret = ?;
        case(stateReg)
          ds_left:
            ret = False;
          ds_right:
            ret = True;
          ds_both:
            ret = True;
          default: //ds_idle
            ret = False;
        endcase

        return ret;
      endmethod
    endinterface;

endmodule