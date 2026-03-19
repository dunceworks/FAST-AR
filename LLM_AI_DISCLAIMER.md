Each .sv file contains a disclaimer to illustrate how LLMs/AI was used to write them. In most cases, AI was used for small code completion such as module instantiation.

For block designs in Vivado, I quickly realized how *bad* LLMs are at understanding what's going on. Due to this, LLMs were used to analyze .tcl files to detect glaring issues with the design or to note changes that Vivado automatically made to IPs without my knowledge (such as Vivado resetting my clock_wizard output freq...).

For actual FPGA implementation, Python was used to generate quick test scripts (in python) to expedite testing of synthesized block diagrams in PYNQ.

External sources were then used in place of AI with minimal AI intervention in designing block diagrams.
External resources include:
IP Documentation
--> https://docs.amd.com/r/en-US/pg201-zynq-ultrascale-plus-processing-system (MPSoC)
--> https://docs.amd.com/r/en-US/pg103-v-tpg/Interface (Video test pattern generator)
--> https://docs.amd.com/r/en-US/pg016_v_tc (Video timing controller)
--> 

User Guides
--> https://www.hackster.io/nikilthapa/4k-tpg-video-streaming-in-kria-kv260-baremetal-part-1-c0c9d6 (Used to guide Displayport output design... we'll see if it helps at all though)
--> https://www.reddit.com/r/FPGA/comments/1rwb770/finally_got_xilinx_dpu_running_on_petalinux_20252/ (Used for DPU guidance in Vivado2025... and yes it's a reddit post. An in progress guide is linked in the thread)
--> will paste later (Used for MIPI in)
