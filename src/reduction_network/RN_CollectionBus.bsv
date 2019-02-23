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
import Fifo::*;

import DataTypes::*;
import GenericInterface::*;
import RN_Types::*;

import MatrixArbiter::*;

interface RN_CollectionBus;
  interface Vector#(RN_NumCollectionBusInputPorts, GI_InputDataPorts) inputDataPorts;
  interface GI_OutputDataPorts outputDataPorts;
endinterface

(* synthesize *)
module mkRN_CollectionBus(RN_CollectionBus);
  Reg#(Bool) initReg <- mkReg(False);
  Vector#(RN_NumCollectionBusInputPorts, Fifo#(RN_CollectionBusIngressFifoDepth, Data)) inputData <- replicateM(mkPipelineFifo);
  Fifo#(RN_CollectionBusEngressFifoDepth, Data) outputData <- mkBypassFifo;
  GenericArbiter#(RN_NumCollectionBusInputPorts) busArbiter <- mkMatrixArbiter(valueOf(RN_NumCollectionBusInputPorts));

  function Bit#(RN_NumCollectionBusInputPorts) getArbitReqBits;
    Bit#(RN_NumCollectionBusInputPorts) reqBit = 0;

    for(Integer inPrt = 0; inPrt < valueOf(RN_NumCollectionBusInputPorts) ; inPrt = inPrt + 1) begin
      reqBit[inPrt] = inputData[inPrt].notEmpty? 1 : 0;
    end

    return reqBit;
  endfunction

  rule doInit(!initReg);
    busArbiter.initialize;
    initReg <= True;
  endrule

  rule fwdData;
    let reqBits = getArbitReqBits();

    if(reqBits != 0) begin
      Data outData = ?;
      let arbitRes <- busArbiter.getArbit(reqBits);
      
      for(Integer inPrt = 0; inPrt < valueOf(RN_NumCollectionBusInputPorts); inPrt = inPrt +1) begin
        if(arbitRes[inPrt] == 1) begin
          outData = inputData[inPrt].first;
          inputData[inPrt].deq;
        end
      end

      outputData.enq(outData);
    end
  endrule

  Vector#(RN_NumCollectionBusInputPorts, GI_InputDataPorts) inputDataPortsDef;
  for(Integer prt = 0; prt < valueOf(RN_NumCollectionBusInputPorts); prt = prt+1) begin
    inputDataPortsDef[prt] = 
      interface GI_InputDataPorts
        method Action putData(Data data);
          inputData[prt].enq(data);
        endmethod
      endinterface;
  end

  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts =
    interface GI_OutputDataPorts
      method ActionValue#(Data) getData;
        outputData.deq;
        return outputData.first;
      endmethod
    endinterface;

endmodule