call rem_files.bat

::Following coregen commands to be uncommented  when the parameter DEBUG_EN is changed from 0 to 1 in ddr2_ctrl_v5.v/.vhd file.
::coregen -b makeproj.bat
::coregen -p . -b icon4_cg.xco
::coregen -p . -b vio_async_in96_cg.xco
::coregen -p . -b vio_async_in192_cg.xco
::coregen -p . -b vio_sync_out32_cg.xco
::coregen -p . -b vio_async_in100_cg.xco

::del *.ncf
echo Synthesis Tool: XST

mkdir "../synth/__projnav" > ise_flow_results.txt
mkdir "../synth/xst" >> ise_flow_results.txt
mkdir "../synth/xst/work" >> ise_flow_results.txt

xst -ifn xst_run.txt -ofn mem_interface_top.syr -intstyle ise >> ise_flow_results.txt
ngdbuild -intstyle ise -dd ../synth/_ngo -nt timestamp -uc ddr2_ctrl_v5.ucf -p xc5vlx50tff1136-1 ddr2_ctrl_v5.ngc ddr2_ctrl_v5.ngd >> ise_flow_results.txt

map -intstyle ise -detail -w -logic_opt off -ol high -xe n -t 1 -cm area -o ddr2_ctrl_v5_map.ncd ddr2_ctrl_v5.ngd ddr2_ctrl_v5.pcf >> ise_flow_results.txt
par -w -intstyle ise -ol high -xe n ddr2_ctrl_v5_map.ncd ddr2_ctrl_v5.ncd ddr2_ctrl_v5.pcf >> ise_flow_results.txt
trce -e 3 -xml ddr2_ctrl_v5 ddr2_ctrl_v5.ncd -o ddr2_ctrl_v5.twr ddr2_ctrl_v5.pcf >> ise_flow_results.txt
bitgen -intstyle ise -f mem_interface_top.ut ddr2_ctrl_v5.ncd >> ise_flow_results.txt

echo done!
