NASM ?= nasm
ASMFLAGS += -g -f elf64
RM ?= rm

TARGETS := 0_basic 1_io 2_addr 3_jump 4_leaf 5_nonleaf
CTARGETS := 6_libc 7_float

.PHONY: all clean
all: $(TARGETS) $(CTARGETS)

$(TARGETS): Makefile
$(CTARGETS): Makefile

$(CTARGETS): LDFLAGS += -dynamic-linker /lib64/ld-linux-x86-64.so.2 /lib64/crt1.o /lib64/crti.o
$(CTARGETS): LDLIBS += -lc /lib64/crtn.o

%.o: %.asm
	$(NASM) $(ASMFLAGS) $<

%: %.o
	$(LD) $(LDFLAGS) -o $@ $< $(LDLIBS)

clean:
	rm -f $(TARGETS) $(CTARGETS)
