TESTBENCH = tb_core
FPU_SOURCES = fadd.vhd fcmp.vhd fdiv.vhd finv.vhd fmul.vhd fneg.vhd fsqrt.vhd fsub.vhd ftoi_func.vhd itof_func.vhd fpu_common.vhd
SOURCES =  alu.vhd blockram.vhd core_internal.vhd core.vhd sim_sram.vhd sram_controller.vhd tb_core.vhd type.vhd util.vhd u232c_in.vhd u232c_out.vhd fpu.vhd $(addprefix ../fpu/, $(FPU_SOURCES))
GHDLC = ghdl
GHDLFLAGS  = -g --ieee=synopsys --mb-comments -fexplicit
GHDL_SIM_OPT = --stop-time=20ms

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
