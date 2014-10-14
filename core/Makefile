TESTBENCH = 
OBJECTS = common.o alu.o

GHDLC = ghdl
GHDLFLAGS  = -fexplicit --ieee=synopsys
GHDL_SIM_OPT = --stop-time=1ms --ieee-asserts=disable

.PHONY: clean
all: $(TESTBENCH)

$(OBJECTS): %.o: %.vhd
	$(GHDLC) -a $(GHDLFLAGS) $^

$(TESTBENCH): $(OBJECTS)
	$(GHDLC) -e $(GHDLFLAGS) $@
	$(GHDLC) -r $(GHDLFLAGS) $@ $(GHDL_SIM_OPT) --vcd=$@.vcd

clean :
	$(GHDLC) --clean
	rm *.vcd work-obj93.fc
