/*

Copyright (C) 2012

Arvind <arvind@csail.mit.edu>
Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


/*
This file contains many FIFO implementations
1) Conflict Free FIFO with 2 elements
2) Pipeline FIFO with 1 element
3) Bypass FIFO with 1 element
4) Conflict Free FIFO with n elements (ptr based implementation)
5) Pipeline FIFO with n elements (ptr based implementation)
6) Searchable n-element FIFO has an extra search method added to the n-element FIFOs
   a) Searchable conflict-free n-element FIFO
   b) Searchable pipelined n-element FIFO

Clear always happens after enq and deq (but before canonicalize when applicable)
All these FIFOs have been tested with various pipelines. In particular n-element FIFO can be put in place of the respective 2-element or 1-element FIFO

*/

import CReg::*;
import Vector::*;

interface Fifo#(numeric type n, type t);
  method Bool notFull;
  method Action enq(t x);
  method Bool notEmpty;
  method Action deq;
  method t first;
  method Action clear;
endinterface

/*
// This Fifo2 <- mkCFFifo generates a two element FIFO where enq and deq are conflict free
// {notEmpty, first} < deq < clear < canon
// notFull < enq < clear < canon
// deq conflict free with enq
module mkCFFifo(Fifo#(2, t)) provisos(Bits#(t, tSz));
  CReg#(3, t) da <- mkCReg(?);
  CReg#(3, Bool) va <- mkCReg(False);
  CReg#(3, t) db <- mkCReg(?);
  CReg#(3, Bool) vb <- mkCReg(False);

  rule canon if(vb[2] && !va[2]);
    da[2] <= db[2];
    va[2] <= True;
    vb[2] <= False;
  endrule

  method Bool notFull = !vb[0];

  method Action enq(t x) if(!vb[0]);
    db[0] <= x;
    vb[0] <= True;
  endmethod

  method Bool notEmpty = va[0];

  method Action deq if (va[0]);
    va[0] <= False;
  endmethod

  method t first if(va[0]);
    return da[0];
  endmethod

  method Action clear;
    vb[1] <= False;
    va[1] <= False;
  endmethod
endmodule
*/

/*
// This generates a one element FIFO where deq < enq
// {notEmpty, first} < deq < notFull < enq < clear
module mkPipelineFifo(Fifo#(1, t)) provisos(Bits#(t, tSz));
  Reg#(t) data <- mkRegU;
  CReg#(3, Bool) full <- mkCReg(False);

  method Bool notFull = !full[1];

  method Action enq(t x) if(!full[1]);
    data <= x;
    full[1] <= True;
  endmethod

  method Bool notEmpty = full[0];

  method Action deq if(full[0]);
    full[0] <= False;
  endmethod

  method t first if(full[0]);
    return data;
  endmethod

  method Action clear;
    full[2] <= False;
  endmethod
endmodule
*/

/*
// A bypass FIFO implementation
// notFull < enq < {notEmpty, first} < deq < clear
module mkBypassFifo(Fifo#(1, t)) provisos(Bits#(t, tSz));
  CReg#(2, t) data <- mkCReg(?);
  CReg#(3, Bool) full <- mkCReg(False);

  method Bool notFull = !full[0];

  method Action enq(t x) if(!full[0]);
    data[0] <= x;
    full[0] <= True;
  endmethod

  method Bool notEmpty = full[1];

  method Action deq if(full[1]);
    full[1] <= False;
  endmethod

  method t first if(full[1]);
    return data[1];
  endmethod

  method Action clear;
    full[2] <= False;
  endmethod
endmodule
*/
// A Conflict free implementation of n element FIFO
// {notEmpty, first} < deq < clear < canonicalize
// notFull < enq < clear < canonicalize
// deq conflict free with enq
// canonicalize has no effect after clear anyway

module mkCFFifo(Fifo#(n, t)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
  CReg#(3, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(3, Bit#(sz1)) deqP <- mkCReg(0);
  CReg#(3, Bool) enqEn <- mkCReg(True);
  CReg#(3, Bool) deqEn <- mkCReg(False);
  CReg#(2, t)                 tempData <- mkCReg(?);
  CReg#(2, Maybe#(Bit#(sz1))) tempEnqP <- mkCReg(Invalid);

  rule canonicalize;
    Bit#(sz1) cnt = enqP[2] >= deqP[2]? enqP[2] - deqP[2]: 
                                   (enqP[2]%nb + nb) - deqP[2]%nb;
    if(!enqEn[2] && cnt != nb) enqEn[2] <= True;
    if(!deqEn[2] && cnt != 0) deqEn[2] <= True;

    if(isValid(tempEnqP[1]))
    begin
      data[validValue(tempEnqP[1])] <= tempData[1];
      tempEnqP[1] <= Invalid;
    end
  endrule

  method Bool notFull = enqEn[0];

  method Action enq(t x) if(enqEn[0]);
    tempData[0] <= x;
    tempEnqP[0] <= Valid (enqP[0]%nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    enqEn[0] <= False;
  endmethod

  method Bool notEmpty = deqEn[0];

  method Action deq if(deqEn[0]);
    deqP[0] <= (deqP[0] + 1)%n2;
    deqEn[0] <= False;
  endmethod

  method t first if(deqEn[0]);
    return data[deqP[0]%nb];
  endmethod

  method Action clear;
    enqP[1] <= 0;
    deqP[1] <= 0;
    enqEn[1] <= True;
    deqEn[1] <= False;
  endmethod
endmodule

// A pipelined implementation of n element FIFO
// {notEmpty, first} < deq < notFull < enq < clear

module mkPipelineFifo(Fifo#(n, t)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
  CReg#(2, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(2, Bit#(sz1)) deqP <- mkCReg(0);

  Bit#(sz1) cnt0 = enqP[0] >= deqP[0]? enqP[0] - deqP[0]:
                                       (enqP[0]%nb + nb) - deqP[0]%nb;
  Bit#(sz1) cnt1 = enqP[0] >= deqP[1]? enqP[0] - deqP[1]:
                                       (enqP[0]%nb + nb) - deqP[1]%nb;

  method Bool notFull = cnt1 < nb;

  method Action enq(t x) if(cnt1 < nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    data[enqP[0]%nb] <= x;
  endmethod

  method Bool notEmpty = cnt0 != 0;

  method Action deq if(cnt0 != 0);
    deqP[0] <= (deqP[0] + 1)%n2;
  endmethod

  method t first if(cnt0 != 0);
    return data[deqP[0]%nb];
  endmethod

  method Action clear;
    enqP[1] <= 0;
    deqP[1] <= 0;
  endmethod
endmodule

// A Bypass implementation of n element FIFO
// notFull < enq < {notEmpty, first} < deq < clear

module mkBypassFifo(Fifo#(n, t)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, CReg#(2, t)) data <- replicateM(mkCReg(?));
  CReg#(2, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(2, Bit#(sz1)) deqP <- mkCReg(0);

  Bit#(sz1) cnt0 = enqP[0] >= deqP[0]? enqP[0] - deqP[0]:
                                       (enqP[0]%nb + nb) - deqP[0]%nb;
  Bit#(sz1) cnt1 = enqP[1] >= deqP[0]? enqP[1] - deqP[0]:
                                       (enqP[1]%nb + nb) - deqP[0]%nb;

  method Bool notFull = cnt0 < nb;

  method Action enq(t x) if(cnt0 < nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    data[enqP[0]%nb][0] <= x;
  endmethod

  method Bool notEmpty = cnt1 != 0;

  method Action deq if(cnt1 != 0);
    deqP[0] <= (deqP[0] + 1)%n2;
  endmethod

  method t first if(cnt1 != 0);
    return data[deqP[0]%nb][1];
  endmethod

  method Action clear;
    enqP[1] <= 0;
    deqP[1] <= 0;
  endmethod
endmodule



// Searchable FIFO has an extra search method
interface SFifo#(numeric type n, type t, type st);
  method Bool notFull;
  method Action enq(t x);
  method Bool notEmpty;
  method Action deq;
  method Bool search(st s);
  method t first;
  method Action clear;
endinterface

// search is conflict-free with {enq, deq, first, notFull, notEmpty}
// search <  clear < canonicalize
module mkCFSFifo#(function Bool isFound(t v, st k))(SFifo#(n, t, st)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
  CReg#(3, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(3, Bit#(sz1)) deqP <- mkCReg(0);
  CReg#(3, Bool) enqEn <- mkCReg(True);
  CReg#(3, Bool) deqEn <- mkCReg(False);
  CReg#(2, t)                 tempData <- mkCReg(?);
  CReg#(2, Maybe#(Bit#(sz1))) tempEnqP <- mkCReg(Invalid);
  CReg#(2, Maybe#(Bit#(sz1))) tempDeqP <- mkCReg(Invalid);

  Bit#(sz1) cnt0 = enqP[0] >= deqP[0]? enqP[0] - deqP[0]: 
                                 (enqP[0]%nb + nb) - deqP[0]%nb;
  Bit#(sz1) cnt2 = enqP[2] >= deqP[2]? enqP[2] - deqP[2]: 
                                 (enqP[2]%nb + nb) - deqP[2]%nb;
  rule canonicalize;
    if(!enqEn[2] && cnt2 != nb) enqEn[2] <= True;
    if(!deqEn[2] && cnt2 != 0) deqEn[2] <= True;

    if(isValid(tempEnqP[1]))
    begin
      data[validValue(tempEnqP[1])] <= tempData[1];
      tempEnqP[1] <= Invalid;
    end

    if(isValid(tempDeqP[1]))
    begin
      deqP[0] <= validValue(tempDeqP[1]);
      tempDeqP[1] <= Invalid;
    end
  endrule

  method Bool notFull = enqEn[0];

  method Action enq(t x) if(enqEn[0]);
    tempData[0] <= x;
    tempEnqP[0] <= Valid (enqP[0]%nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    enqEn[0] <= False;
  endmethod

  method Bool notEmpty = deqEn[0];

  method Action deq if(deqEn[0]);
    tempDeqP[0] <= Valid ((deqP[0] + 1)%n2);
    deqEn[0] <= False;
  endmethod

  method t first if(deqEn[0]);
    return data[deqP[0]%nb];
  endmethod

  method Bool search(st s);
    Bool ret = False;
    for(Bit#(sz1) i = 0; i < nb; i = i + 1)
    begin
      let ptr = (deqP[0] + i)%nb;
      if(isFound(data[ptr], s) && i < cnt0)
        ret = True;
    end
    return ret;
  endmethod

  method Action clear;
    enqP[1] <= 0;
    deqP[1] <= 0;
    enqEn[1] <= True;
    deqEn[1] <= False;
  endmethod
endmodule

// {notEmpty, first} < deq < search
// search CF {enq, notFull}
// search < clear
module mkPipelineSFifo#(function Bool isFound(t v, st k))(SFifo#(n, t, st)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1), Bits#(st, stz));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
  CReg#(3, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(2, Bit#(sz1)) deqP <- mkCReg(0);

  Bit#(sz1) cnt0 = enqP[0] >= deqP[0]? enqP[0] - deqP[0]:
                                       (enqP[0]%nb + nb) - deqP[0]%nb;
  Bit#(sz1) cnt1 = enqP[0] >= deqP[1]? enqP[0] - deqP[1]:
                                       (enqP[0]%nb + nb) - deqP[1]%nb;

  method Bool notFull = cnt1 < nb;

  method Action enq(t x) if(cnt1 < nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    data[enqP[0]%nb] <= x;
  endmethod

  method Bool notEmpty = cnt0 != 0;

  method Action deq if(cnt0 != 0);
    deqP[0] <= (deqP[0] + 1)%n2;
  endmethod

  method t first if(cnt0 != 0);
    return data[deqP[0]%nb];
  endmethod

  method Bool search(st s);
    Bool ret = False;
    for(Bit#(sz1) i = 0; i < nb; i = i + 1)
    begin
      let ptr = (deqP[1] + i)%nb;
      if(isFound(data[ptr], s) && i < cnt1)
        ret = True;
    end
    return ret;
  endmethod

  method Action clear;
    enqP[2] <= 0;
    deqP[1] <= 0;
  endmethod
endmodule

// Searchable Count FIFO has an extra search method which returns the count of the number of elements found
interface SCountFifo#(numeric type n, type t, type st);
  method Bool notFull;
  method Action enq(t x);
  method Bool notEmpty;
  method Action deq;
  method Bit#(TLog#(TAdd#(n, 1))) search(st s);
  method t first;
  method Action clear;
endinterface

// search is conflict-free with {enq, deq, first, notFull, notEmpty}
// search <  clear < canonicalize
module mkCFSCountFifo#(function Bool isFound(t v, st k))(SCountFifo#(n, t, st)) provisos(Bits#(t, tSz), Add#(n, 1, n1), Log#(n1, sz), Add#(sz, 1, sz1));
  Integer ni = valueOf(n);
  Bit#(sz1) nb = fromInteger(ni);
  Bit#(sz1) n2 = 2*nb;
  Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
  CReg#(3, Bit#(sz1)) enqP <- mkCReg(0);
  CReg#(3, Bit#(sz1)) deqP <- mkCReg(0);
  CReg#(3, Bool) enqEn <- mkCReg(True);
  CReg#(3, Bool) deqEn <- mkCReg(False);
  CReg#(2, t)                 tempData <- mkCReg(?);
  CReg#(2, Maybe#(Bit#(sz1))) tempEnqP <- mkCReg(Invalid);
  CReg#(2, Maybe#(Bit#(sz1))) tempDeqP <- mkCReg(Invalid);

  Bit#(sz1) cnt0 = enqP[0] >= deqP[0]? enqP[0] - deqP[0]: 
                                 (enqP[0]%nb + nb) - deqP[0]%nb;
  Bit#(sz1) cnt2 = enqP[2] >= deqP[2]? enqP[2] - deqP[2]: 
                                 (enqP[2]%nb + nb) - deqP[2]%nb;
  rule canonicalize;
    if(!enqEn[2] && cnt2 != nb) enqEn[2] <= True;
    if(!deqEn[2] && cnt2 != 0) deqEn[2] <= True;

    if(isValid(tempEnqP[1]))
    begin
      data[validValue(tempEnqP[1])] <= tempData[1];
      tempEnqP[1] <= Invalid;
    end

    if(isValid(tempDeqP[1]))
    begin
      deqP[0] <= validValue(tempDeqP[1]);
      tempDeqP[1] <= Invalid;
    end
  endrule

  method Bool notFull = enqEn[0];

  method Action enq(t x) if(enqEn[0]);
    tempData[0] <= x;
    tempEnqP[0] <= Valid (enqP[0]%nb);
    enqP[0] <= (enqP[0] + 1)%n2;
    enqEn[0] <= False;
  endmethod

  method Bool notEmpty = deqEn[0];

  method Action deq if(deqEn[0]);
    tempDeqP[0] <= Valid ((deqP[0] + 1)%n2);
    deqEn[0] <= False;
  endmethod

  method t first if(deqEn[0]);
    return data[deqP[0]%nb];
  endmethod

  method Bit#(TLog#(TAdd#(n, 1))) search(st s);
    Bit#(TLog#(TAdd#(n, 1))) ret = 0;
    for(Bit#(sz1) i = 0; i < nb; i = i + 1)
    begin
      let ptr = (deqP[0] + i)%nb;
      if(isFound(data[ptr], s) && i < cnt0)
        ret = ret + 1;
    end
    return ret;
  endmethod

  method Action clear;
    enqP[1] <= 0;
    deqP[1] <= 0;
    enqEn[1] <= True;
    deqEn[1] <= False;
  endmethod
endmodule

