ADDI       sp, sp, -32            # Decrease stack pointer by 32 (allocate space for saving registers)
SW         ra, 28(sp)             # Save return address (ra) to stack at offset 28
SW         s8, 24(sp)             # Save s8 register to stack at offset 24
MOV        s8, sp                 # Move current stack pointer to s8 (save stack pointer)
LI         a0, 10                 # Load immediate value (n) 10 into register a0 (input argument)
JAL        0x44                   # Jump and link to function at address 0x44 (Fibonacci calculation)
MOV        v1, v0                 # Move the result from v0 (Fibonacci number) to v1
LUI        v0, 0x1                # Load upper immediate 0x1 into v0
SW         v1, -32768(v0)         # Store the Fibonacci result (v1) at memory location (v0 - 32768)
MOV        v0, zero               # Clear register v0 (set to 0)
MOV        sp, s8                 # Restore original stack pointer (s8) from the saved value
LW         ra, 28(sp)             # Load return address (ra) from stack
LW         s8, 24(sp)             # Load s8 register from stack
ADDI       sp, sp, 32             # Restore stack pointer (deallocate space)
JR         ra                     # Jump to the return address (return from function)

ADDI       sp, sp, -40            # Decrease stack pointer by 40 (allocate space for function arguments and local variables)
SW         ra, 36(sp)             # Save return address (ra) to stack at offset 36
SW         s8, 32(sp)             # Save s8 register to stack at offset 32
SW         s0, 28(sp)             # Save s0 register to stack at offset 28
MOV        s8, sp                 # Move current stack pointer to s8 (save stack pointer)
SW         a0, 40(s8)             # Store the input argument (a0) at stack location 40(s8)
LW         v0, 40(s8)             # Load the input argument (a0) back from stack into v0
BNE        v0, zero, 0x78         # If v0 != 0 (argument != 0), branch to address 0x78 (not base case)
MOV        v0, zero               # If base case, set v0 to 0
J          0xcc                   # Jump to address 0xcc (return to caller)

LW         v1, 40(s8)             # Load the argument (n) from stack into v1
LI         v0, 1                  # Load immediate value 1 into v0
BNE        v1, v0, 0x94           # If n != 1, branch to 0x94 (proceed with recursive calls)
LI         v0, 1                  # If n == 1, set v0 to 1 (base case of Fibonacci)
J          0xcc                   # Jump to 0xcc (return result)

LW         v0, 40(s8)             # Load the argument (n) from stack into v0
ADDI       v0, v0, -1             # Decrement n by 1
MOV        a0, v0                 # Move n-1 to argument register a0 for recursive call
JAL        0x44                   # Jump and link to Fibonacci function at 0x44
MOV        s0, v0                 # Save the result of Fibonacci(n-1) in s0

LW         v0, 40(s8)             # Load the argument (n) from stack again
ADDI       v0, v0, -2             # Decrement n by 2 (for Fibonacci(n-2))
MOV        a0, v0                 # Move n-2 to argument register a0 for recursive call
JAL        0x44                   # Jump and link to Fibonacci function at 0x44
ADDU       v0, s0, v0             # Add the results of Fibonacci(n-1) and Fibonacci(n-2), store in v0

MOV        sp, s8                 # Restore stack pointer (s8) from saved value
LW         ra, 36(sp)             # Load return address (ra) from stack
LW         s8, 32(sp)             # Load s8 register from stack
LW         s0, 28(sp)             # Load s0 register from stack
ADDI       sp, sp, 40             # Restore stack pointer (deallocate space)
JR         ra                     # Jump to return address (return from function)
