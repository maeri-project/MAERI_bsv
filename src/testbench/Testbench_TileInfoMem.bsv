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


import TileTypes::*;
import RN_Types::*;
import CR_Types::*;
import SU_Types::*;

import CR_TileInfoMemory::*;


typedef 150 FinalCycle;

(* synthesize *)
module mkTestbench();
  Reg#(StatData) cycleCounter <- mkReg(0);

  CR_TileInfoMemory tileInfoMem <- mkCR_TileInfoMemory;

  rule runTestbench;
    if(cycleCounter == fromInteger(valueOf(FinalCycle)) ) begin
      $finish;
    end
    else begin
      cycleCounter <= cycleCounter + 1;
    end
  endrule

  rule readConfig;

    if(cycleCounter == 15) begin
      $display("Dim K: %d", tileInfoMem.getDimK);
      $display("Dim C: %d", tileInfoMem.getDimC);
      $display("Dim R: %d", tileInfoMem.getDimR);
      $display("Dim S: %d", tileInfoMem.getDimS);
      $display("Dim Y: %d", tileInfoMem.getDimY);
      $display("Dim X: %d", tileInfoMem.getDimX);

      $display("TileSz K: %d", tileInfoMem.getTileSzK);
      $display("TileSz C: %d", tileInfoMem.getTileSzC);
      $display("TileSz R: %d", tileInfoMem.getTileSzR);
      $display("TileSz S: %d", tileInfoMem.getTileSzS);
      $display("TileSz Y: %d", tileInfoMem.getTileSzY);
      $display("TileSz X: %d", tileInfoMem.getTileSzX);

      $display("EdgeK: %d", tileInfoMem.getEdgeK);
      $display("EdgeC: %d", tileInfoMem.getEdgeC);
      $display("EdgeR: %d", tileInfoMem.getEdgeR);
      $display("EdgeS: %d", tileInfoMem.getEdgeS);
      $display("EdgeY: %d", tileInfoMem.getEdgeY);
      $display("EdgeX: %d", tileInfoMem.getEdgeX);
      
      $display("IterK: %d", tileInfoMem.getNumIterK);
      $display("IterC: %d", tileInfoMem.getNumIterC);
      $display("IterR: %d", tileInfoMem.getNumIterR);
      $display("IterS: %d", tileInfoMem.getNumIterS);
      $display("IterY: %d", tileInfoMem.getNumIterY);
      $display("IterX: %d", tileInfoMem.getNumIterX);

      $display("NumMultSwitches: %d", tileInfoMem.getNumMultSwitches);
      $display("NumMappedVNs: %d", tileInfoMem.getNumMappedVNs);
      $display("VNSize: %d", tileInfoMem.getVNSize);

   end
  endrule


endmodule