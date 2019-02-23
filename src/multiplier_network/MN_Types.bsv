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

import AcceleratorConfig::*;
import DataTypes::*;

//typedef 16 NumMultSwitches;

typedef 2 MS_IngressFifoDepth;
typedef 2 MS_EgressFifoDepth;

typedef 2 MS_WeightFifoDepth;
typedef 2 MS_IfMapFifoDepth;
typedef 2 MS_PSumFifoDepth;
typedef 2 MS_FwdFifoDepth;

//typedef Maybe#(DataClass) DataForwardConfig;

/* Controller Internal */
typedef Bit#(4) MS_State;

MS_State ms_idle = 4'b0000;
MS_State ms_initSteadyVal = 4'b0001;
MS_State ms_runLEdgeFirst = 4'b0010;
MS_State ms_runLEdge = 4'b0011;
MS_State ms_runMiddleFirst = 4'b0100;
MS_State ms_runMiddle = 4'b0101;
MS_State ms_runREdgeFirst = 4'b0110;
MS_State ms_runREdge = 4'b0111;
//MS_State ms_idle = 4'b0111;
//MS_State ms_idle = 4'b1000;


typedef Bit#(16) MS_PSumCount;


/* Controller Output Signals */
typedef Bit#(2) MS_IptSelect;

MS_IptSelect ms_iptNothing = 2'b00;
MS_IptSelect ms_iptStationary = 2'b01;
MS_IptSelect ms_iptStream = 2'b10;

typedef Bit#(2) MS_FwdSelect;

MS_FwdSelect ms_fwdNothing = 2'b00;
MS_FwdSelect ms_fwdInput = 2'b01;
MS_FwdSelect ms_fwdFwd = 2'b10;

typedef Bit#(2) MS_ArgSelect;

MS_FwdSelect ms_argNothing = 2'b00;
MS_FwdSelect ms_argInput = 2'b01;
MS_FwdSelect ms_argFwd = 2'b10;

/*
typedef struct {
  MultSwitchID swID;
  MultSwitchID vnSz;
  DataClass stationaryData;
  VNID vnID;
} MultiplierSwitchDebugInfo deriving (Bits, Eq);
*/

typedef struct {
  MS_State state;
  MS_PSumCount psumCount;
} MS_Config deriving (Bits, Eq);

typedef Vector#(NumMultSwitches, MS_Config) MN_Config;
