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
import Connectable::*;

import AcceleratorConfig::*;
import DataTypes::*;
import GenericInterface::*;
import RN_Types::*;

import RN_SglReductionSwitch::*;
import RN_DblReductionSwitch::*;
import RN_CollectionBus::*;

interface RN_ReductionNetwork_ControlPorts;
  method Action putConfig(RN_Config newConfig);
endinterface

interface RN_ReductionNetwork;
  interface Vector#(NumMultSwitches, GI_InputDataPorts) inputDataPorts;
  interface Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPorts;
  interface RN_ReductionNetwork_ControlPorts controlPorts;
endinterface

(* synthesize *)
module mkRN_ReductionNetwork(RN_ReductionNetwork);

  `ifdef DEBUG_RN
    Reg#(Bool) inited <- mkReg(False);
  `endif

  Vector#(RN_NumDblRSes, RN_DblReductionSwitch) dblReductionSwitches <- replicateM(mkRN_DblReductionSwitch);
  Vector#(RN_NumSglRSes, RN_SglReductionSwitch) sglReductionSwitches <- replicateM(mkRN_SglReductionSwitch);
  Vector#(RN_NumColletionBuses, RN_CollectionBus) collectionBuses <- replicateM(mkRN_CollectionBus);

  `ifdef DEBUG_RN
  rule initialize(!inited);
      for(Integer sw = 0; sw < valueOf(RN_NumDblRSes); sw = sw +1) begin
        dblReductionSwitches[sw].controlPorts.initialize(fromInteger(sw));
      end

      for(Integer sw = 0; sw < valueOf(RN_NumSglRSes); sw = sw +1) begin
        sglReductionSwitches[sw].controlPorts.initialize(fromInteger(sw));
      end
    inited <= True;
  endrule
  `endif

  /* Interconnect double reduction switches */
  for(Integer lv = 2; lv < valueOf(RN_NumLevels) ; lv = lv+1) begin
    Integer numDblRSesInLV = 2 ** (lv-1) - 1;      
    Integer lvFirstDblRSID = 2 ** (lv-1) - lv;
    Integer nextLvFirstDblRSID = 2 ** (lv) - lv - 1;

    /* Connect to single reduction switches at edges */
    mkConnection(dblReductionSwitches[lvFirstDblRSID].outputDataPorts[0].getData,
                   sglReductionSwitches[lv*2-3].inputDataPorts[1].putData);
                
    mkConnection(dblReductionSwitches[nextLvFirstDblRSID-1].outputDataPorts[1].getData,
                   sglReductionSwitches[lv*2-2].inputDataPorts[0].putData);

    if(lv != valueOf(RN_NumLevels)-1) begin
      for(Integer sw = 0; sw < numDblRSesInLV; sw = sw+1) begin
        Integer receiverRS_ID = lvFirstDblRSID + sw;
        Integer fisrtSenderRS_ID = nextLvFirstDblRSID + sw * 2;

        mkConnection(dblReductionSwitches[fisrtSenderRS_ID].outputDataPorts[1].getData,
                      dblReductionSwitches[receiverRS_ID].inputDataPorts[0].putData);

        mkConnection(dblReductionSwitches[fisrtSenderRS_ID+1].outputDataPorts[0].getData,
                      dblReductionSwitches[receiverRS_ID].inputDataPorts[1].putData);

        mkConnection(dblReductionSwitches[fisrtSenderRS_ID+1].outputDataPorts[1].getData,
                      dblReductionSwitches[receiverRS_ID].inputDataPorts[2].putData);

        mkConnection(dblReductionSwitches[fisrtSenderRS_ID+2].outputDataPorts[0].getData,
                      dblReductionSwitches[receiverRS_ID].inputDataPorts[3].putData);
      end
    end
  end

  /* Interconnect single reduction switches */
  mkConnection(sglReductionSwitches[1].outputDataPorts.getData,
                 sglReductionSwitches[0].inputDataPorts[0].putData);

  mkConnection(sglReductionSwitches[2].outputDataPorts.getData,
                 sglReductionSwitches[0].inputDataPorts[1].putData);


  for(Integer lv = 1; lv < valueOf(RN_NumLevels)-1; lv = lv+1) begin
    Integer lvFirstSglRSID = 2*lv - 1;
    Integer nextLvFirstSglRSID = 2*lv + 1;

    mkConnection(sglReductionSwitches[nextLvFirstSglRSID].outputDataPorts.getData,
                   sglReductionSwitches[lvFirstSglRSID].inputDataPorts[0].putData);

    mkConnection(sglReductionSwitches[nextLvFirstSglRSID+1].outputDataPorts.getData,
                   sglReductionSwitches[lvFirstSglRSID+1].inputDataPorts[1].putData);
  end

  /* Interconnect double reduction switches to collect buses */
  for(Integer sw = 0; sw < valueOf(RN_NumDblRSes); sw = sw+1) begin
    Integer prtID = 2 * (sw / valueOf(RN_NumColletionBuses));
    Integer busID = sw % valueOf(RN_NumColletionBuses);

    mkConnection(dblReductionSwitches[sw].resultsDataPorts[0].getData,
                   collectionBuses[busID].inputDataPorts[prtID].putData);
    mkConnection(dblReductionSwitches[sw].resultsDataPorts[1].getData,
                   collectionBuses[busID].inputDataPorts[prtID+1].putData);    
  end


  /* Interconnect single reduction switches to collect buses */
  for(Integer sw = 0; sw < valueOf(RN_NumSglRSes); sw = sw+1) begin
    Integer prtIDBase = 2 * valueOf(RN_NumDblRSes) / valueOf(RN_NumColletionBuses) + 1;
    Integer prtID = prtIDBase + sw / valueOf(RN_NumColletionBuses);
    Integer busID = sw % valueOf(RN_NumColletionBuses);


    mkConnection(sglReductionSwitches[sw].resultsDataPorts.getData,
                   collectionBuses[busID].inputDataPorts[prtID].putData);
  end


  /* Interfaces */
  Vector#(NumMultSwitches, GI_InputDataPorts) inputDataPortsDef;
  for(Integer inPrt = 0; inPrt < valueOf(NumMultSwitches); inPrt = inPrt + 1) begin
    inputDataPortsDef[inPrt] = 
      interface GI_InputDataPorts
        method Action putData(Data data);

          if(inPrt == 0 || inPrt == 1) begin
            Integer targSGRS_ID = 2 * (valueOf(RN_NumLevels)-1) - 1;
            sglReductionSwitches[targSGRS_ID].inputDataPorts[inPrt].putData(data);
          end
          else if(inPrt == valueOf(NumMultSwitches)-2) begin
            Integer targSGRS_ID = 2 * (valueOf(RN_NumLevels)-1);          
            sglReductionSwitches[targSGRS_ID].inputDataPorts[0].putData(data);
          end
          else if(inPrt == valueOf(NumMultSwitches)-1) begin
            Integer targSGRS_ID = 2 * (valueOf(RN_NumLevels)-1);          
            sglReductionSwitches[targSGRS_ID].inputDataPorts[1].putData(data);
          end          
          else begin
            Integer targDBRS_ID_Base = 2 ** (valueOf(RN_NumLevels)-2) -(valueOf(RN_NumLevels)-1); 
            Integer targDBRS_ID_Ofs = (inPrt - 2) / 4;
            Integer targDBRS_PortID = (inPrt - 2) % 4;

            dblReductionSwitches[targDBRS_ID_Base+targDBRS_ID_Ofs].inputDataPorts[targDBRS_PortID].putData(data);
          end
        endmethod
      endinterface;
  end

  Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer outPrt = 0; outPrt < valueOf(RN_NumColletionBuses) ; outPrt = outPrt + 1) begin
    outputDataPortsDef[outPrt] = 
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          let ret <- collectionBuses[outPrt].outputDataPorts.getData;
          return ret;
        endmethod
      endinterface;
  end
  
  interface inputDataPorts = inputDataPortsDef;
  interface outputDataPorts = outputDataPortsDef;

  interface controlPorts =
    interface RN_ReductionNetwork_ControlPorts
      method Action putConfig(RN_Config newConfig);
        let dblRSConfig = newConfig.dblRSNetworkConfig;
        let sglRSConfig = newConfig.sglRSNetworkConfig;

        for(Integer sw = 0; sw < valueOf(RN_NumDblRSes); sw = sw +1) begin
          dblReductionSwitches[sw].controlPorts.putConfig(dblRSConfig[sw]);
        end

        for(Integer sw = 0; sw < valueOf(RN_NumSglRSes); sw = sw +1) begin
          sglReductionSwitches[sw].controlPorts.putConfig(sglRSConfig[sw]);
        end
      endmethod
    endinterface;

endmodule