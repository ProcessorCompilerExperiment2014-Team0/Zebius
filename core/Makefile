TESTBENCH = tb_core
SOURCES =  alu.vhd blockram.vhd core_internal.vhd core.vhd loader.vhd sim_sram.vhd sram_controller.vhd tb_core.vhd type.vhd util.vhd u232c_in.vhd u232c_out.vhd
GHDLC = ghdl
GHDLFLAGS  = -g --ieee=synopsys
GHDL_SIM_OPT = --stop-time=1ms

.PHONY: clean $(TESTBENCH)
all: $(TESTBENCH)

work-obj93.cf:
	$(GHDLC) -i $(GHDLFLAGS) $(SOURCES)

$(TESTBENCH): work-obj93.cf
	$(GHDLC) -m $(GHDLFLAGS) $@
	$(GHDLC) -r $(GHDLFLAGS) $@ $(GHDL_SIM_OPT) --wave=$@.ghw

clean :
	$(GHDLC) --clean
	rm *.ghw work-obj93.cf
