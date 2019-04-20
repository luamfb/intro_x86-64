NASM ?= nasm
ASMFLAGS += -g -f elf64
CC ?= cc
RM ?= rm

TARGETS := 0_basic 1_io 2_addr 3_jump 4_leaf 5_nonleaf
CTARGETS := 6_libc 7_float

.PHONY: all clean
all: $(TARGETS) $(CTARGETS)

$(TARGETS): $(addsuffix .o, $(TARGETS))
	$(LD) $(LDFLAGS) -o $@ $< $(LDLIBS)

$(CTARGETS): $(addsuffix .o, $(CTARGETS))
	$(CC) -no-pie -o $@ $<

%.o: %.asm
	$(NASM) $(ASMFLAGS) $<

clean:
	rm -f $(TARGETS) $(CTARGETS) \
	       	$(addsuffix .o, $(TARGETS)) $(addsuffix .o, $(CTARGETS))
