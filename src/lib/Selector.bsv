/******************************************************************************
Copyright (c) 2018 Georgia Instititue of Technology

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
import RWire::*;

interface GenericSelectorInputs;
  method Action reqSelection;
endinterface

interface GenericSelectorOutputs;
  method Bool isGranted;
endinterface

interface GenericIdxSelectorOutputs#(numeric type numInputs);
  method Maybe#(Bit#(TLog#(numInputs))) grantedIdx;
endinterface


interface GenericSelector#(numeric type numInputs, numeric type numOutputs);
  interface Vector#(numInputs, GenericSelectorInputs) selectorInputPorts;
  interface Vector#(numInputs, GenericSelectorOutputs) selectorOutputPorts;
endinterface

interface GenericIdxSelector#(numeric type numInputs, numeric type numOutputs);
  interface Vector#(numInputs, GenericSelectorInputs) selectorInputPorts;
  interface Vector#(numOutputs, GenericIdxSelectorOutputs#(numInputs)) selectorOutputPorts;
endinterface



module mkGenericSelector#(Integer numIpt, Integer numOpt)(GenericSelector#(numInputs, numOutputs));

  Vector#(numInputs, RWire#(Bool)) reqLines <- replicateM(mkRWire);
  Vector#(numInputs, RWire#(Bool)) grtLines <- replicateM(mkRWire);

  rule doSelection;
    Integer cnt = 0;
    
    for(Integer prt = 0; prt< numIpt; prt = prt+1) begin
      if(cnt < numOpt && isValid(reqLines[prt].wget)) begin
        grtLines[prt].wset(?);
        cnt = cnt + 1;
      end
    end
  endrule

  Vector#(numInputs, GenericSelectorInputs) selectorInputPortsTemp;
  Vector#(numInputs, GenericSelectorOutputs) selectorOutputPortsTemp;

  for(Integer prt = 0; prt< numIpt; prt = prt +1) begin
    selectorInputPortsTemp[prt] = 
      interface GenericSelectorInputs
        method Action reqSelection; 
          reqLines[prt].wset(?);
        endmethod
      endinterface;

    selectorOutputPortsTemp[prt] = 
      interface GenericSelectorOutputs
        method Bool isGranted = isValid(grtLines[prt].wget);
      endinterface;
  end

  interface selectorOutputPorts = selectorOutputPortsTemp;
  interface selectorInputPorts = selectorInputPortsTemp;
endmodule

module mkGenericIdxSelector#(Integer numIpt, Integer numOpt)(GenericIdxSelector#(numInputs, numOutputs));

  Vector#(numInputs, RWire#(Bool)) reqLines <- replicateM(mkRWire);
  Vector#(numInputs, RWire#(Bit#(TLog#(numInputs)))) grtLines <- replicateM(mkRWire);

  rule doSelection;
    Bit#(32) cnt = 0;
    
    for(Integer prt = 0; prt< numIpt; prt = prt+1) begin
      if(cnt < fromInteger(numOpt) && isValid(reqLines[prt].wget)) begin
        grtLines[cnt].wset(fromInteger(prt));
        cnt = cnt + 1;
        `ifdef DEBUG_IDXSELECTOR
          $display("[Selector] Granted request from port %d. Resp ID: %d", prt, cnt);
        `endif
      end
    end
  endrule

  Vector#(numInputs, GenericSelectorInputs) selectorInputPortsTemp;
  Vector#(numOutputs, GenericIdxSelectorOutputs#(numInputs)) selectorOutputPortsTemp;

  for(Integer prt = 0; prt< numIpt; prt = prt +1) begin
    selectorInputPortsTemp[prt] = 
      interface GenericSelectorInputs
        method Action reqSelection;
          `ifdef DEBUG_IDXSELCTOR
            $display("[Selector] Recieved request from port %d", prt);
          `endif
          reqLines[prt].wset(?);
        endmethod
      endinterface;
  end

  for(Integer prt = 0; prt< numOpt; prt = prt +1) begin
    selectorOutputPortsTemp[prt] = 
      interface GenericIdxSelectorOutputs
        method Maybe#(Bit#(TLog#(numInputs))) grantedIdx = grtLines[prt].wget;
      endinterface;
  end

  interface selectorOutputPorts = selectorOutputPortsTemp;
  interface selectorInputPorts = selectorInputPortsTemp;
endmodule





