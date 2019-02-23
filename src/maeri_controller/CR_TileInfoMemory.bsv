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
import RegFile::*;
import Fifo::*;

import TileTypes::*;
import CR_Types::*;
import SU_Types::*;

interface CR_TileInfoMemory;
  method Bool isInited;

  method StatData getDimK;
  method StatData getDimC;
  method StatData getDimR;
  method StatData getDimS;
  method StatData getDimY;
  method StatData getDimX;

  method StatData getTileSzK;
  method StatData getTileSzC;
  method StatData getTileSzR;
  method StatData getTileSzS;
  method StatData getTileSzY;
  method StatData getTileSzX;

  method StatData getEdgeK;
  method StatData getEdgeC;
  method StatData getEdgeR;
  method StatData getEdgeS;
  method StatData getEdgeY;
  method StatData getEdgeX;

  method StatData getNumIterK;
  method StatData getNumIterC;
  method StatData getNumIterR;
  method StatData getNumIterS;
  method StatData getNumIterY;
  method StatData getNumIterX;

  method StatData getNumMultSwitches;
  method StatData getNumMappedVNs;
  method StatData getVNSize;

endinterface

(* synthesize *)
module mkCR_TileInfoMemory(CR_TileInfoMemory);

  Reg#(Bool) inited <- mkReg(False);
  RegFile#(CR_TileInfoIdx, CR_TileInfoData) tileInfoMem <- mkRegFileFullLoad("Layer_Info.vmh");

  Vector#(NumLayerDimensions, Reg#(StatData)) layerDimSizes <- replicateM(mkReg(0));
  Vector#(NumLayerDimensions, Reg#(StatData)) dimTileSizes <- replicateM(mkReg(0));
  Vector#(NumLayerDimensions, Reg#(StatData)) dimEdgeSizes <- replicateM(mkReg(0));
  Vector#(NumLayerDimensions, Reg#(StatData)) dimNumIters <- replicateM(mkReg(0));

  Reg#(StatData) numMultSwitches <- mkReg(0);
  Reg#(StatData) numMappedVNs <- mkReg(0);
  Reg#(StatData) vnSz <- mkReg(0);


  Reg#(CR_TileInfoIdx) processCounter <- mkReg(0);

  rule getInfo(!inited);
    LayerDimension targetDim = truncate(processCounter/2);
    CR_TileInfoIdx mode = processCounter % 2;
    //StatData endCount = zeroExtend(dimEnd) * 2 -1;
    if(targetDim < dimEnd) begin
      let rawTileInfo = tileInfoMem.sub(processCounter);
      if(mode == 0) begin
        layerDimSizes[targetDim] <= zeroExtend(getTileInfo_DimSz(rawTileInfo));
        dimTileSizes[targetDim] <= zeroExtend(getTileInfo_TileSz(rawTileInfo));
      end
      else begin
        dimEdgeSizes[targetDim] <= zeroExtend(getTileInfo_DimEdgeSz(rawTileInfo));
        dimNumIters[targetDim] <= zeroExtend(getTileInfo_DimNumIters(rawTileInfo));
      end
    end
    else begin
      let rawTileInfo = tileInfoMem.sub(processCounter);
      numMultSwitches <= zeroExtend(getTileInfo_NumMultSwitches(rawTileInfo));
      numMappedVNs <= zeroExtend(getTileInfo_NumMappedVNs(rawTileInfo));
      let vnSzInfo = tileInfoMem.sub(processCounter +1);
      vnSz <= zeroExtend(getTileInfo_VNSize(vnSzInfo));
      inited <= True;
    end

    processCounter <= processCounter + 1;
  endrule

  method Bool isInited = inited;


  method StatData getDimK if(inited);
    return layerDimSizes[dimK];
  endmethod 
  method StatData getDimC if(inited);
    return layerDimSizes[dimC];
  endmethod 
  method StatData getDimR if(inited);
    return layerDimSizes[dimR];
  endmethod 
  method StatData getDimS if(inited);
    return layerDimSizes[dimS];
  endmethod 
  method StatData getDimY if(inited);
    return layerDimSizes[dimY];
  endmethod 
  method StatData getDimX if(inited);
    return layerDimSizes[dimX];
  endmethod 

  method StatData getTileSzK if(inited);
    return dimTileSizes[dimK];
  endmethod
  method StatData getTileSzC if(inited);
    return dimTileSizes[dimC];
  endmethod
  method StatData getTileSzR if(inited);
    return dimTileSizes[dimR];
  endmethod
  method StatData getTileSzS if(inited);
    return dimTileSizes[dimS];
  endmethod
  method StatData getTileSzY if(inited);
    return dimTileSizes[dimY];
  endmethod
  method StatData getTileSzX if(inited);
    return dimTileSizes[dimX];
  endmethod

  method StatData getEdgeK if(inited);
    return dimEdgeSizes[dimK];
  endmethod
  method StatData getEdgeC if(inited);
    return dimEdgeSizes[dimC];
  endmethod
  method StatData getEdgeR if(inited);
    return dimEdgeSizes[dimR];
  endmethod
  method StatData getEdgeS if(inited);
    return dimEdgeSizes[dimS];
  endmethod
  method StatData getEdgeY if(inited);
    return dimEdgeSizes[dimY];
  endmethod
  method StatData getEdgeX if(inited);
    return dimEdgeSizes[dimX];
  endmethod

  method StatData getNumIterK if(inited);
    return dimNumIters[dimK];
  endmethod
  method StatData getNumIterC if(inited);
    return dimNumIters[dimC];
  endmethod
  method StatData getNumIterR if(inited);
    return dimNumIters[dimR];
  endmethod
  method StatData getNumIterS if(inited);
    return dimNumIters[dimS];
  endmethod
  method StatData getNumIterY if(inited);
    return dimNumIters[dimY];
  endmethod
  method StatData getNumIterX if(inited);
    return dimNumIters[dimX];
  endmethod

  method StatData getNumMultSwitches if(inited);
    return numMultSwitches;
  endmethod

  method StatData getNumMappedVNs if(inited);
  	return numMappedVNs;
  endmethod

  method StatData getVNSize if(inited);
  	return vnSz;
  endmethod 

endmodule