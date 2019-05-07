NASM     := nasm
ASMFLAGS += -g -f elf64
CC       := gcc
CCFLAGS  := -g -no-pie 
LD       := ld
LDFLAGS  := 
LDLIBS   :=
RM       := rm

TARGETS  := 0_basic 1_io 2_addr 3_jump 4_leaf 5_nonleaf
CTARGETS := 6_libc 7_float
OBJ      := $(addsuffix .o, $(TARGETS) $(CTARGETS))

.PHONY: all clean
all: $(TARGETS) $(CTARGETS)

$(TARGETS):  %: %.o 
	$(LD) -o $@ $< $(LDFLAGS) $(LDLIBS)

$(CTARGETS): %: %.o 
	$(CC) -o $@ $< $(CCFLAGS) $(LDFLAGS) $(LDLIBS)

$(OBJ): %.o: %.asm
	$(NASM) -o $@ $< $(ASMFLAGS)

clean:
	$(RM) -f $(TARGETS) $(CTARGETS) $(OBJ)