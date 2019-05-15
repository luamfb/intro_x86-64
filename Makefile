NASM     := nasm
ASMFLAGS += -g -f elf64
CC       := gcc
CCFLAGS  := -g -no-pie 
LD       := ld
LDFLAGS  := 
LDLIBS   :=
RM       := rm
MAKE     := make

TARGETS  := 0_basic 1_io 2_addr 3_jump 4_leaf 5_nonleaf
CTARGETS := 6_libc 7_float
OBJ      := $(addsuffix .o, $(TARGETS) $(CTARGETS))

EXTRA_DIRS := 8_asm_c

.PHONY: all clean

all: $(TARGETS) $(CTARGETS)
	@for i in $(EXTRA_DIRS); do $(MAKE) -C $$i $@; done

clean:
	$(RM) -f $(TARGETS) $(CTARGETS) $(OBJ)	
	@for i in $(EXTRA_DIRS); do $(MAKE) -C $$i $@; done

$(TARGETS):  %: %.o 
	$(LD) -o $@ $< $(LDFLAGS) $(LDLIBS)

$(CTARGETS): %: %.o 
	$(CC) -o $@ $< $(CCFLAGS) $(LDFLAGS) $(LDLIBS)

$(OBJ): %.o: %.asm
	$(NASM) -o $@ $< $(ASMFLAGS)