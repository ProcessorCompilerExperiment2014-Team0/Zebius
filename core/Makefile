TESTBENCH = tb_core
OBJECTS =  sim_sram.o common.o component.o loader.o alu.o u232c_out.o sram_controller.o core.o tb_core.o
GHDLC = ghdl
GHDLFLAGS  = -fexplicit --ieee=synopsys
GHDL_SIM_OPT = --stop-time=1us

.PHONY: clean $(TESTBENCH)
all: $(TESTBENCH)

$(OBJECTS): %.o: %.vhd
	$(GHDLC) -a $(GHDLFLAGS) $^

$(TESTBENCH): $(OBJECTS)
	$(GHDLC) -e $(GHDLFLAGS) $@
	$(GHDLC) -r $(GHDLFLAGS) $@ $(GHDL_SIM_OPT) --wave=$@.ghw

clean :
	$(GHDLC) --clean
	rm *.vcd work-obj93.cf
