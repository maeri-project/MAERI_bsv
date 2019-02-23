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


typedef Bit#(2) RN_SGRS_Mode;    // SGRS: single reduction switch
typedef Bit#(4) RN_DBRS_Mode;    // DBRS: double reduction switch
typedef Bit#(2) RN_DBRS_SubMode; 

Bit#(2) rn_dbrs_submode_idle = 2'b00;
Bit#(2) rn_dbrs_submode_addOne = 2'b01;
Bit#(2) rn_dbrs_submode_addTwo = 2'b10;
Bit#(2) rn_dbrs_submode_addThree = 2'b11;


Bit#(2) rn_sgrs_mode_idle = 2'b00;
Bit#(2) rn_sgrs_mode_addTwo = 2'b01;
Bit#(2) rn_sgrs_mode_flowLeft = 2'b10;
Bit#(2) rn_sgrs_mode_flowRight = 2'b11;


typedef TLog#(NumMultSwitches)                            RN_NumLevels;

typedef TSub#(NumMultSwitches, 1)                         RN_NumAdderSwitches;
typedef TSub#(TMul#(RN_NumLevels,2), 1)                   RN_NumSglRSes;
typedef TDiv#(TSub#(RN_NumAdderSwitches, RN_NumSglRSes), 2) RN_NumDblRSes;


//typedef Bit#(TAdd#(1, TLog#(RN_NumLevels)))            RN_LevelID;
//typedef Bit#(TAdd#(TAdd#(RN_NumAdderSwitches), 1)) RN_NodeID;
//typedef Bit#(TAdd#(TLog#(NumMultSwitches), 1))         RN_LeafID;


typedef struct {
  RN_SGRS_Mode mode;
  Bool genOutput;
}  RN_SglRSConfig deriving(Bits, Eq);

typedef struct {
  RN_DBRS_Mode mode;

  Bool genOutputL;
  Bool genOutputR;
}  RN_DblRSConfig deriving(Bits, Eq);

typedef Vector#(RN_NumSglRSes, RN_SglRSConfig) RN_SglRSNetworkConfig;
typedef Vector#(RN_NumDblRSes, RN_DblRSConfig) RN_DblRSNetworkConfig;

typedef struct {
  RN_SglRSNetworkConfig sglRSNetworkConfig;
  RN_DblRSNetworkConfig dblRSNetworkConfig;
} RN_Config deriving(Bits,Eq);


/* Collection Bus */

typedef CollectionBandwidth RN_NumColletionBuses;
typedef TAdd#(TDiv#(NumMultSwitches, RN_NumColletionBuses),1 ) RN_NumCollectionBusInputPorts;

typedef 4 RN_CollectionBusIngressFifoDepth;
typedef 1 RN_CollectionBusEngressFifoDepth;

typedef Bit#(TAdd#(TLog#(NumMultSwitches), 1)) RN_NodeID;

