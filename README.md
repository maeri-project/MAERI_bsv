# MAERI
MAERI: A DNN accelerator with reconfigurable interconnects to support flexible dataflow. This codebase was used in the MAERI HPCA 2019 tutorial.

# About
MAERI is a deep learning inference accelerator that enables fine-grained compute resource allocation at run time.
Relevant publications:
* Hyoukjun Kwon, Ananda Samajdar, and Tushar Krishna, **MAERI: Enabling Flexible Dataflow Mapping over DNN Accelerators via Reconfigurable Interconnects**. _In Proc of the 23rd ACM International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS), Mar 2018_ [pdf](https://synergy.ece.gatech.edu/wp-content/uploads/sites/332/2018/01/maeri_asplos2018.pdf)
* Hyoukjun Kwon, Ananda Samajdar, and Tushar Krishna, **A Communication-Centric Approach for Designing Flexible DNN Accelerators**, _In IEEE Micro Special Issue on Hardware Acceleration, Nov/Dec 2018_ [pdf](https://synergy.ece.gatech.edu/wp-content/uploads/sites/332/2019/01/maeri_ieeemicro2018.pdf)


## Software Requirement
MAERI is written in Bluespec System Verilog (https://bluespec.com/). You need Bluespec Compiler software and license to use this repository. If your affiliation is universities, you can request a free license via Bluespec's university program (https://bluespec.com/university/)

[Update] Bluespec released their compier as an opensource software. For details, please see the following article: https://bluespec.com/2020/01/06/bluespec-inc-to-open-source-its-proven-bsv-high-level-hdl-tools/

[Update] Please check this repo out to get the open-sourced Bluespec Compiler (https://github.com/B-Lang-org/bsc)

## How to change the design parameters?
You can edit number of multiplier switches (similar to the number of PEs in other accelerators), distribution bandwidth, and reduction bandwidth. Please note that those parameters need to be integer numbers of power of two.

## How to compile and run a simulation?
<ul>
  <li> Compilation: "./MAERI -c all" 
  <li> Running a siumulation: "./MAERI -r"
  <li> Please note that you need to copy appropriate config files from config directory. They can be generated from a compiler; We are working on open-sourceing the compiler. Please stay tuned for the update to use arbitrary settings in the simulation
</ul>    

## How to generate Verilog file
"./MAERI -v ACC"

## Notes
This code base is work in progress Some of features such as compiler will be added to this repository. Please stay tuned for udpates.

## Related projects
mRNA: A Mapping Optmizer for MAERI: https://github.com/maeri-project/mRNA

## Contributors
Lead Developer: [Hyoukjun Kwon](https://hyoukjunkwon.com/)
