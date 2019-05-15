NASM     := nasm
ASMFLAGS += -g -f elf64
CC       := gcc
CCFLAGS  := -g -no-pie 
LD       := ld
LDFLAGS  := 
LDLIBS   :=
RM       := rm

C_OBJ     := main.o
OBJ      := funcs.o
PROG     := fact

.PHONY: all clean
all: $(PROG)

$(PROG): $(OBJ) $(C_OBJ)
	$(CC) -o $@ $^

$(OBJ): $(OBJ:%.o=%.asm)
	$(NASM) -o $@ $(ASMFLAGS) $<

$(C_OBJ): $(C_OBJ:%.o=%.c)
	$(CC) -c -o $@ $(CCFLAGS) $<

clean:
	$(RM) -f $(PROG) $(OBJ) $(C_OBJ)
