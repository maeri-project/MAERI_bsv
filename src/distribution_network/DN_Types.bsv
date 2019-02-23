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

typedef Bit#(2) DS_State;

DS_State ds_idle = 2'b00;
DS_State ds_left = 2'b10;
DS_State ds_right = 2'b01;
DS_State ds_both = 2'b11;

typedef DS_State DS_Config;

/* SubTree */
// Design parameters
typedef 4 DN_SubTreeIngressDataFifoDepth;
typedef 4 DN_SubTreeIngressControlFifoDepth;

typedef 4 DN_SubTreeEgressDataFifoDepth;
typedef 1 DN_SubTreeEgressControlFifoDepth;


// Deduced parameters
typedef DistributionBandwidth DN_NumSubTrees;
typedef TDiv#(NumMultSwitches, DN_NumSubTrees) DN_SubTreeSz;
typedef TSub#(DN_SubTreeSz, 1) DN_NumSubTreeDistSwitches;
typedef TLog#(DN_SubTreeSz) DN_NumSubTreeLvs;
typedef Bit#(TAdd#(TLog#(DN_NumSubTrees), 4)) DN_SubTreeID;

// Internal definition
typedef Bit#(1) DN_Epoch;
DN_Epoch dn_initEpoch = 1'b0;

// Data types
typedef Bit#(DN_SubTreeSz) DN_SubTreeDestBits;
typedef DN_SubTreeDestBits DN_TopSubTreeConfig;
typedef Vector#(DN_NumSubTreeDistSwitches, DS_State) DN_SubTreeConfig;
DN_TopSubTreeConfig dn_topSubtree_nullConfig = 0;


typedef 16 DN_SubTreeIngressFifoDepth;
typedef 16 DN_IngressFifoDepth;
typedef 1 DN_EgressFifoDepth;

typedef Bit#(NumMultSwitches) DN_DestBits;

typedef DN_DestBits DN_Config;

function DN_SubTreeDestBits getSubTreeConfig(DN_Config destBits, DN_SubTreeID subTreeID);
  DN_SubTreeDestBits ret = destBits[fromInteger(valueOf(DN_SubTreeSz))*(subTreeID+1) -1 : fromInteger(valueOf(DN_SubTreeSz)) * subTreeID];
  return ret;
endfunction


// For debugging
`ifdef DEBUG_DN
typedef Bit#(TAdd#(TLog#(NumMultSwitches), 1)) DN_NodeID;

`endif