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
import CReg::*;
import GenericInterface::*;
import AcceleratorConfig::*;
import DataTypes::*;
import DN_Types::*;
import RN_Types::*;
import MN_Types::*;
import CR_Types::*;
import SU_Types::*;

import CR_RN_ConfigurationMemory::*;
import CR_TileInfoMemory::*;


import DN_DistributionNetwork::*;
import MN_MultiplierNetwork::*;
import RN_ReductionNetwork::*;

import MAERI_Accelerator::*;


/* Dataflow description
  let vnSize = R*S;
  let numVNs = floor(NumMultSwitches/vnSize);

  tMap(1, 1) C
  sMap(numVNs, numVNs) K
  tMap(1, 1) Y
  tMap(1, 1) X
  tMap(Sz(R), Sz(R)) R
  tMap(Sz(S), Sz(S)) S
*/


(* synthesize *)
module mkTestbench();
  /* Configuration memories */
  CR_TileInfoMemory tileInfo_mem <- mkCR_TileInfoMemory;
  CR_RN_ConifgurationMemory rn_config_mem <- mkCR_RN_ConfigurationMemory;

  /* MAERI Top Module */
  MAERI_Accelerator dut <- mkMAERI_Accelerator;

  /* Traffic generation states */
  Reg#(Bool) inited <- mkReg(False);
  Reg#(Bool) configedRN <- mkReg(False);
  Reg#(Bool) countUniqueInput <- mkReg(True);

  Reg#(Maybe#(StatData)) targetGatherCount <- mkReg(Invalid);
  Reg#(StatData) trafficGenCount <- mkReg(0);
  Reg#(TrafficGenStatus) state <- mkReg(Idle);
  Reg#(StatData) kCounter <- mkReg(0);
  Reg#(StatData) cCounter <- mkReg(0);
  Reg#(StatData) yCounter <- mkReg(0);
  Reg#(StatData) xCounter <- mkReg(0);
  CReg#(2,Bool) finishReq <- mkCReg(False);
  CReg#(TAdd#(1, CollectionBandwidth), StatData)  pSumRegY <- mkCReg(0);
  CReg#(TAdd#(1, CollectionBandwidth), StatData)  pSumRegC <- mkCReg(0);
  CReg#(TAdd#(1, CollectionBandwidth), StatData)  pSumRegK <- mkCReg(0);

  /* Statistics */
  Reg#(StatData) cycleReg <- mkReg(0);
  CReg#(TAdd#(1, CollectionBandwidth), StatData)   numReceivedPSums <- mkCReg(0);
  CReg#(TAdd#(1, DistributionBandwidth), StatData) numInjectedWeights <- mkCReg(0);
  CReg#(TAdd#(1, DistributionBandwidth), StatData) numInjectedInputs <- mkCReg(0);
  CReg#(TAdd#(1, DistributionBandwidth), StatData) numInjectedUniqueInputs <- mkCReg(0);
  CReg#(TAdd#(1, DistributionBandwidth), StatData) numInputMulticast <- mkCReg(0);

  /* Testbench control signals */
  Bool isKEdge = (kCounter == tileInfo_mem.getDimK - 1);
  Bool isCEdge = (cCounter == tileInfo_mem.getDimC - 1);
  Bool isYEdge = (yCounter == tileInfo_mem.getDimY - tileInfo_mem.getDimR );
  Bool isXEdge = (xCounter == tileInfo_mem.getDimX - tileInfo_mem.getDimS );

  StatData vnSize = tileInfo_mem.getVNSize;
  StatData numMappedVNs = tileInfo_mem.getNumMappedVNs;
  Bool isVNMappingKEdge = tileInfo_mem.getDimK - kCounter < numMappedVNs;

  StatData numActualMappedVNs = isVNMappingKEdge? tileInfo_mem.getDimK - kCounter : numMappedVNs;
  StatData numActualActiveMultSwitches = isVNMappingKEdge? 
                                       (tileInfo_mem.getDimK - kCounter) * vnSize 
                                       :  numMappedVNs * vnSize; 

  StatData assertDimS = (tileInfo_mem.getDimS > 0)? tileInfo_mem.getDimS : 1;

  StatData outputWidth = (tileInfo_mem.getDimX - tileInfo_mem.getDimS+ 1);
  StatData outputHeight = (tileInfo_mem.getDimY - tileInfo_mem.getDimR+ 1);

  StatData numOutputsPerOutputChannel = outputWidth * outputHeight;


  rule runTestBench;
    if(!inited && tileInfo_mem.isInited) begin
      $dumpvars;
      $dumpon;

      StatData totalNumPOutputs = tileInfo_mem.getDimK * tileInfo_mem.getDimC 
                                 * (tileInfo_mem.getDimY - tileInfo_mem.getDimR +1)
                                 * (tileInfo_mem.getDimX - tileInfo_mem.getDimS +1);


      targetGatherCount <= Valid(totalNumPOutputs);
      $display("@cycle %d: Testbench is initialized. TargetPSumCount: %d", cycleReg, totalNumPOutputs);
      inited <= True;
      state <= WeightInitConfig;
    end

    cycleReg <= cycleReg + 1;
  endrule

  rule configureRN(!configedRN);
    let rn_config <- rn_config_mem.getRN_Config;
    dut.controlPorts.rnControlPorts.putConfig(rn_config);
    configedRN <= True; 


    for(Integer dbrs = 0; dbrs < valueOf(RN_NumDblRSes); dbrs = dbrs +1 ) begin
      let mode = rn_config.dblRSNetworkConfig[dbrs].mode;
      RN_DBRS_SubMode modeL = truncateLSB(mode);
      RN_DBRS_SubMode modeR = truncate(mode);

      let genOutputL = rn_config.dblRSNetworkConfig[dbrs].genOutputL;
      let genOutputR = rn_config.dblRSNetworkConfig[dbrs].genOutputR;


      `ifdef DEBUG_TESTBENCH
      $display("DBRS %d config", dbrs);
      $display("ModeL: %b    , ModeR: %b", modeL, modeR);
      if(genOutputL) begin
        $display("Generates an output at Left");
      end

      if(genOutputR) begin
        $display("Generates an output at Right");
      end
      `endif

    end

    for(Integer sgrs = 0; sgrs < valueOf(RN_NumSglRSes); sgrs = sgrs +1 ) begin
      let mode = rn_config. sglRSNetworkConfig[sgrs].mode;
      let genOutput = rn_config. sglRSNetworkConfig[sgrs].genOutput;
    `ifdef DEBUG_TESTBENCH
      $display("SGRS %d config", sgrs);
      $display("Mode: %b", mode);
      if(genOutput) begin
        $display("Generates an output");
      end
    `endif
    end


  endrule

  rule doWeightInitConfig(state == WeightInitConfig);
    MN_Config mnConfig = newVector;
    for(StatData idx = 0; idx < fromInteger(valueOf(NumMultSwitches)); idx = idx+1) begin

      mnConfig[idx] = MS_Config {
        state: ms_initSteadyVal,
        psumCount: 0
      };
    end
    dut.controlPorts.mnControlPorts.putConfig(mnConfig, numActualActiveMultSwitches);
    state <= WeightInitData;
  endrule


  rule doWeightInitData(state == WeightInitData);
    DN_Config newConfig = 0;

    for(StatData inPrt = 0; inPrt < fromInteger(valueOf(DistributionBandwidth)); inPrt = inPrt + 1) begin
      let baseIdx = inPrt * fromInteger(valueOf(DN_SubTreeSz));
      let targetIdx = baseIdx + trafficGenCount;
      newConfig[targetIdx] = (targetIdx < numActualActiveMultSwitches)? 1 : 0;
    end

    if(trafficGenCount == fromInteger(valueOf(DN_SubTreeSz)) -1) begin
      state <= InitWeightTransfer;
      trafficGenCount <= 0;
    end
    else begin
      trafficGenCount <= trafficGenCount + 1;
    end

    for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt +1) begin
      let subTreeConfig = getSubTreeConfig(newConfig, fromInteger(prt));
      if(subTreeConfig != dn_topSubtree_nullConfig) begin
        dut.controlPorts.dnControlPorts[prt].putConfig(subTreeConfig);     
        let newWeight = truncate(cycleReg) + fromInteger(prt);
        dut.inputDataPorts[prt].putData(newWeight);

        `ifdef DEBUG_TESTBENCH
          $display("@%d, MAERI received a weight from input port %d. destination = %b", cycleReg, prt, subTreeConfig);
        `endif
        let sentWeights = countOnes(subTreeConfig);
        numInjectedWeights[prt] <= numInjectedWeights[prt] + zeroExtend(pack(sentWeights));
      end
    end

  endrule

  rule doWeightTransfer(state == InitWeightTransfer);
    if(dut.controlPorts.isReadyForNextConfig) begin
      state <= InputInitConfig;
    end
  endrule

  rule doInputInitConfig(state == InputInitConfig);
    MN_Config mnConfig = newVector;
    for(StatData idx = 0; idx < fromInteger(valueOf(NumMultSwitches)); idx = idx+1) begin
      MS_State nextState = ?;

      if((idx % tileInfo_mem.getDimS)  == 0) begin
        nextState = ms_runLEdgeFirst;
      end
      else if((idx % tileInfo_mem.getDimS) == (tileInfo_mem.getDimS-1)) begin
        nextState = ms_runREdgeFirst;
      end
      else begin
        nextState = ms_runMiddleFirst;
      end

      MS_PSumCount targPSumCount = truncate(tileInfo_mem.getDimX - tileInfo_mem.getDimS +1);

      mnConfig[idx] = MS_Config {
        state: nextState,
        psumCount: targPSumCount
      };

      `ifdef DEBUG_TESTBENCH
        $display("@%d, MAERI generates a config for ms[%d] ", cycleReg, idx);
        if(nextState == ms_runLEdgeFirst) begin
          $display("MS state: LEdge");
        end
        else if(nextState == ms_runREdgeFirst) begin
          $display("MS state: REdge");
        end
        else begin
          $display("MS state: Middle");
        end
        $display("TargetPSumCount: ", targPSumCount);
      `endif
    end
    dut.controlPorts.mnControlPorts.putConfig(mnConfig, numActualActiveMultSwitches);
    state <= InputInitData;
    trafficGenCount <= 0;
  endrule

  rule doInputInitData(state == InputInitData);
    DN_Config newConfig = 0;

    for(StatData ms = 0; ms < fromInteger(valueOf(NumMultSwitches)); ms = ms + 1) begin
      //Not the most intutive way to do it but it's for compilation time optimization
      if(ms < numActualActiveMultSwitches && trafficGenCount < vnSize) begin
        if(ms % vnSize == trafficGenCount) begin
          newConfig[ms] = 1;
        end
      end
    end

    if(trafficGenCount == vnSize -1) begin
      if(countUniqueInput) begin
        if(yCounter == 0) begin
          numInjectedUniqueInputs[0] <= numInjectedUniqueInputs[0] + vnSize;
        end
        else begin
          numInjectedUniqueInputs[0] <= numInjectedUniqueInputs[0] + tileInfo_mem.getDimS;
        end
      end
      state <= InitInputTransfer;
      trafficGenCount <= 0;
    end
    else begin
      trafficGenCount <= trafficGenCount + 1;
    end

    for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt +1) begin
      let subTreeConfig = getSubTreeConfig(newConfig, fromInteger(prt));
      if(subTreeConfig != dn_topSubtree_nullConfig) begin
        dut.controlPorts.dnControlPorts[prt].putConfig(subTreeConfig);     
        let newInput = truncate(cycleReg) + fromInteger(prt);
        dut.inputDataPorts[prt].putData(newInput);

        let sentInputs = countOnes(subTreeConfig);
        numInjectedInputs[prt] <= numInjectedInputs[prt] + zeroExtend(pack(sentInputs));

        `ifdef DEBUG_TESTBENCH
          $display("@%d, MAERI received an input from input port %d. destination = %b", cycleReg, prt, subTreeConfig);
        `endif
      end
    end
  endrule

  rule doInitInputTransfer(state == InitInputTransfer);
    if(dut.controlPorts.isReadyForNextConfig) begin
      state <= SteadyState;
      trafficGenCount <= 0;
      xCounter <= 1;
    end
  endrule

  rule doSteadyState(state == SteadyState);
    DN_Config newConfig = 0;

    for(StatData ms = 0; ms < fromInteger(valueOf(NumMultSwitches)); ms = ms + 1) begin
      //Not the most intutive way to do it but it's for compilation time optimization
      if(ms < numActualActiveMultSwitches && trafficGenCount < tileInfo_mem.getDimR) begin
        if( ((ms / assertDimS)  % tileInfo_mem.getDimR) == trafficGenCount) begin
          if(assertDimS > 0 && (ms % assertDimS == 0)) begin
            newConfig[ms] = 1;
          end
        end
      end
    end

    if(newConfig != 0 && countUniqueInput) begin
      if(yCounter == 0) begin
        numInjectedUniqueInputs[0] <= numInjectedUniqueInputs[0] + 1;
      end
      else begin
        if(trafficGenCount == tileInfo_mem.getDimR -1) begin
          numInjectedUniqueInputs[0] <= numInjectedUniqueInputs[0] + 1;
        end
      end
    end

    numInputMulticast[0] <= numInputMulticast[0] + 1;

    `ifdef DEBUG_TESTBENCH
    if(newConfig != 0) begin
      $display("Steady state @ x = %d, NewConfig: %b", xCounter, newConfig);
    end
    `endif

    for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt +1) begin
      let subTreeConfig = getSubTreeConfig(newConfig, fromInteger(prt));
      if(subTreeConfig != dn_topSubtree_nullConfig) begin
        dut.controlPorts.dnControlPorts[prt].putConfig(subTreeConfig);     
        let newInput = truncate(cycleReg) + fromInteger(prt);
        dut.inputDataPorts[prt].putData(newInput);

        let numSentInputs = countOnes(pack(subTreeConfig));
        numInjectedInputs[prt] <= numInjectedInputs[prt] + zeroExtend(pack(numSentInputs));

        `ifdef DEBUG_TESTBENCH
          $display("@%d, MAERI received an input from input port %d. destination = %b", cycleReg, prt, subTreeConfig);
        `endif
      end
    end

    if(trafficGenCount < tileInfo_mem.getDimR -1) begin
      trafficGenCount <= trafficGenCount + 1;
    end 
    else if(trafficGenCount == tileInfo_mem.getDimR -1) begin
      if(!isXEdge) begin
        xCounter <= xCounter + 1;
        trafficGenCount <= 0;
      end
      else begin
        Bool isKTileEdge = ((kCounter + numActualMappedVNs) == tileInfo_mem.getDimK);
        if(!isYEdge) begin
          `ifdef DEBUG_TESTBENCH
            $display("Xcounter : %d, Ycounter: %d, Kcounter: %d, Ccounter: %d, row transition", xCounter, yCounter, kCounter, cCounter);
            $display("YDim: %d, RDim: %d, KDim: %d, CDim: %d", tileInfo_mem.getDimY, tileInfo_mem.getDimR, tileInfo_mem.getDimK, tileInfo_mem.getDimC);
          `endif
          state <= RowTransition;
          yCounter <= yCounter + 1;
        end
        else if (!isKTileEdge) begin 
          // OutputChannelTransition;
          `ifdef DEBUG_TESTBENCH
            $display("Xcounter : %d, Ycounter: %d, Kcounter: %d, Ccounter: %d, output channel transition", xCounter, yCounter, kCounter, cCounter);
            $display("YDim: %d, RDim: %d, KDim: %d, CDim: %d", tileInfo_mem.getDimY, tileInfo_mem.getDimR, tileInfo_mem.getDimK, tileInfo_mem.getDimC);
          `endif          
          state <= OutputChannelTransition;
          yCounter <= 0; 
        end
        else if (!isCEdge) begin
          // InputChannelTransition;
          `ifdef DEBUG_TESTBENCH
            $display("Xcounter : %d, Ycounter: %d, Kcounter: %d, Ccounter: %d, input channel transition", xCounter, yCounter, kCounter, cCounter);
            $display("YDim: %d, RDim: %d, KDim: %d, CDim: %d", tileInfo_mem.getDimY, tileInfo_mem.getDimR, tileInfo_mem.getDimK, tileInfo_mem.getDimC);
          `endif                    
          state <= InputChannelTransition;
          yCounter <= 0; 
          kCounter <= 0;
          cCounter <= cCounter + 1;
        end
        else begin
          state <= FinishState;
          finishReq[0] <= True;
        end

        trafficGenCount <= 0;
        xCounter <= 0;
      end
    end
  endrule

  rule doRowTransition(state == RowTransition);
    if(pSumRegY[valueOf(CollectionBandwidth)] == numActualMappedVNs * outputWidth) begin
      state <= InputInitConfig;
      pSumRegY[valueOf(CollectionBandwidth)] <= 0;
      `ifdef DEBUG_TESTBENCH
        $display("Finish row-transition state. Moving to input init config");
      `endif
    end
    `ifdef DEBUG_TESTBENCH
      $display("Xcounter : %d, Ycounter: %d, Kcounter: %d, Ccounter: %d", xCounter, yCounter, kCounter, cCounter);
      $display("YDim: %d, RDim: %d, KDim: %d, CDim: %d", tileInfo_mem.getDimY, tileInfo_mem.getDimR, tileInfo_mem.getDimK, tileInfo_mem.getDimC);

      $display("Ycount :%d, Waiting for PSumY: pSumRegY = %d / %d ", yCounter, pSumRegY[valueOf(CollectionBandwidth)], numActualMappedVNs * outputWidth);
    `endif
  endrule


  rule doOutputChannelTransition(state == OutputChannelTransition);
    if(pSumRegK[valueOf(CollectionBandwidth)] == numActualMappedVNs * numOutputsPerOutputChannel) begin
      state <= WeightInitConfig;
      kCounter <= kCounter + numActualMappedVNs;
      pSumRegY[valueOf(CollectionBandwidth)] <= 0;
      pSumRegK[valueOf(CollectionBandwidth)] <= 0;
      countUniqueInput <= False;
    end
    `ifdef DEBUG_TESTBENCH
      $display("Waiting for PSumK: pSumRegK = %d / (%d x %d) ", pSumRegK[valueOf(CollectionBandwidth)], numActualMappedVNs, numOutputsPerOutputChannel);
    `endif
  endrule

  rule doInputChannelTransition(state == InputChannelTransition);
    if(pSumRegC[valueOf(CollectionBandwidth)] == tileInfo_mem.getDimK * numOutputsPerOutputChannel) begin
      state <= WeightInitConfig;
      pSumRegY[valueOf(CollectionBandwidth)] <= 0;
      pSumRegK[valueOf(CollectionBandwidth)] <= 0;
      pSumRegC[valueOf(CollectionBandwidth)] <= 0;
      countUniqueInput <= True;
    end
    `ifdef DEBUG_TESTBENCH
      $display("Waiting for PSumC: pSumRegC = %d / %d", pSumRegC[valueOf(CollectionBandwidth)], tileInfo_mem.getDimK * numOutputsPerOutputChannel );
    `endif
  endrule

  for(Integer outPrt = 0; outPrt < valueOf(CollectionBandwidth); outPrt = outPrt + 1) begin
    rule getOutput(isValid(targetGatherCount));
      let outData <- dut.outputDataPorts[outPrt].getData;
      numReceivedPSums[outPrt] <= numReceivedPSums[outPrt] + 1;
      pSumRegC[outPrt] <= pSumRegC[outPrt] + 1;
      pSumRegK[outPrt] <= pSumRegK[outPrt] + 1;
      pSumRegY[outPrt] <= pSumRegY[outPrt] + 1;
      if((numReceivedPSums[outPrt] +1) % 100 == 0) begin
        $display("@%d, MAERI generated a partial output from output port %d. Partial outputCount: (%d / %d)", cycleReg, outPrt,  numReceivedPSums[outPrt] +1, validValue(targetGatherCount));
      end
    endrule
  end

  rule countPhase(isValid(targetGatherCount));
    if(numReceivedPSums[fromInteger(valueOf(CollectionBandwidth))] >= validValue(targetGatherCount) && finishReq[1] ) begin
      $display("@ Cycle %d: Received all the outputs; Testbench terminates",cycleReg);
      $display(" Layer dimension K = %d, C = %d, R = %d, S = %d, Y= %d, X = %d", tileInfo_mem.getDimK, tileInfo_mem.getDimC, tileInfo_mem.getDimR, tileInfo_mem.getDimS, tileInfo_mem.getDimY, tileInfo_mem.getDimX);
      $display(" Output dimension: %d x %d x %d\n", tileInfo_mem.getDimK, tileInfo_mem.getDimY - tileInfo_mem.getDimR + 1, tileInfo_mem.getDimX - tileInfo_mem.getDimS + 1);

      $display("Number of injected weights: %d", numInjectedWeights[valueOf(DistributionBandwidth)]);
      $display("Number of injected inputs: %d", numInjectedInputs[valueOf(DistributionBandwidth)]);
      $display("Number of injected unique inputs: %d", numInjectedUniqueInputs[valueOf(DistributionBandwidth)]);
      $display("Number of input multicasting: %d", numInputMulticast[valueOf(DistributionBandwidth)]);
      $display("Number of generated partial sums: %d", numReceivedPSums[valueOf(DistributionBandwidth)] * vnSize);
      $display("Number of performed Ops (Multiplication and Addition): %d\n",  numReceivedPSums[valueOf(DistributionBandwidth)] * (2*vnSize-1));

      $display("Total runtime (assuming 1GHz clock): %d ns", cycleReg);
      $dumpoff;
      $finish;
    end
  endrule

endmodule
