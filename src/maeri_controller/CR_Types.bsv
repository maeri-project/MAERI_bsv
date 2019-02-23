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

import AcceleratorConfig::*;

import RN_Types::*;


/* RN Configuration memory types */
typedef Bit#(10) CR_ConfigIdx;
typedef Bit#(32) CR_ConfigData;


typedef Bit#(4) CR_SGRS_ConfigData;
typedef Bit#(8) CR_DBRS_ConfigData;


function CR_DBRS_ConfigData getCR_DBRS_ConfigData(CR_ConfigData fullData, Bit#(6) configIdx);
  Bit#(6) baseIdx = 8 * configIdx;
  Bit#(6) boundIdx = 8 * configIdx + 7;

  return fullData[boundIdx : baseIdx];
endfunction

function RN_DBRS_Mode getDBRS_ModeFromRawData(CR_DBRS_ConfigData rawData);
  let ret = truncateLSB(rawData);
  return ret;
endfunction

function Bool getDBRS_GenOutputL(CR_DBRS_ConfigData rawData);
  return (rawData[3] == 1'b1);
endfunction

function Bool getDBRS_GenOutputR(CR_DBRS_ConfigData rawData);
  return (rawData[2] == 1'b1);
endfunction


function CR_SGRS_ConfigData getCR_SGRS_ConfigData(CR_ConfigData fullData, Bit#(6) configIdx);
  Bit#(6) baseIdx = 4 * configIdx;
  Bit#(6) boundIdx = 4 * configIdx + 3;

  return fullData[boundIdx : baseIdx];
endfunction

function RN_SGRS_Mode getSGRS_ModeFromRawData(CR_SGRS_ConfigData rawData);
  let ret = truncateLSB(rawData);
  return ret;
endfunction

function Bool getSGRS_GenOutput(CR_SGRS_ConfigData rawData);
  return (rawData[1] == 1'b1);
endfunction


typedef TDiv#(RN_NumDblRSes, 4) CR_DBRS_ConfigAddressBound;
typedef TAdd#(TDiv#(RN_NumSglRSes, 4), CR_DBRS_ConfigAddressBound) CR_SGRS_ConfigAddressBound;


/* Tile info memory */
typedef Bit#(32) CR_TileInfoData;
typedef Bit#(6) CR_TileInfoIdx;

typedef Bit#(16) CR_TileInfo;

function CR_TileInfo getTileInfo_DimSz(CR_TileInfoData rawData);
  CR_TileInfo ret = truncateLSB(rawData);
  return ret;
endfunction

function CR_TileInfo getTileInfo_DimEdgeSz(CR_TileInfoData rawData) = getTileInfo_DimSz(rawData);
function CR_TileInfo getTileInfo_NumMultSwitches(CR_TileInfoData rawData) = getTileInfo_DimSz(rawData);


function CR_TileInfo getTileInfo_TileSz(CR_TileInfoData rawData);
  CR_TileInfo ret = truncate(rawData);
  return ret;
endfunction

function CR_TileInfo getTileInfo_DimNumIters(CR_TileInfoData rawData) = getTileInfo_TileSz(rawData);
function CR_TileInfo getTileInfo_NumMappedVNs(CR_TileInfoData rawData) = getTileInfo_TileSz(rawData);
function CR_TileInfo getTileInfo_VNSize(CR_TileInfoData rawData) = getTileInfo_TileSz(rawData);



/* Traffic generator types */

typedef enum{Idle, WeightInitConfig, WeightInitData, InitWeightTransfer, InputInitConfig, InitInputTransfer, InputInitData, SteadyState, RowTransition, OutputChannelTransition, InputChannelTransition, FinishState} TrafficGenStatus deriving(Bits, Eq);


