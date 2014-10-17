TESTBENCH = coretb
OBJECTS = t/coretb.o libs/common.o src/alu.o src/core.o
GHDLC = ghdl
GHDLFLAGS  = -fexplicit --ieee=synopsys
GHDL_SIM_OPT = --stop-time=1ms --ieee-asserts=disable

.PHONY: clean
all: $(TESTBENCH)

$(OBJECTS): %.o: %.vhd
	$(GHDLC) -a $(GHDLFLAGS) $^

$(TESTBENCH): $(OBJECTS)
	$(GHDLC) -e $(GHDLFLAGS) $@
	$(GHDLC) -r $(GHDLFLAGS) $@ $(GHDL_SIM_OPT) --wave=$@.ghw

clean :
	$(GHDLC) --clean
	rm *.vcd work-obj93.cf
