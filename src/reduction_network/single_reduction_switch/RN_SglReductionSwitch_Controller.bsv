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

import RN_Types::*;

interface RN_SglReductionSwitch_Controller_ControlPorts;
  method Action putConfig(RN_SglRSConfig newConfig); 
  method RN_SGRS_Mode getMode;
  method Bool getGenOutput;
endinterface

interface RN_SglReductionSwitch_Controller;
  interface RN_SglReductionSwitch_Controller_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkRN_SglReductionSwitch_Controller(RN_SglReductionSwitch_Controller);

  Reg#(RN_SGRS_Mode) modeReg <- mkReg(rn_sgrs_mode_idle);
  Reg#(Bool)            genOutput <- mkReg(False);

  interface controlPorts =
    interface RN_SglReductionSwitch_Controller_ControlPorts
      method Action putConfig(RN_SglRSConfig newConfig); 
        modeReg <= newConfig.mode;
        genOutput <= newConfig.genOutput;
      endmethod
     
      method RN_SGRS_Mode getMode;
        return modeReg;
      endmethod

      method Bool getGenOutput;
        return genOutput;
      endmethod

    endinterface;

endmodule
