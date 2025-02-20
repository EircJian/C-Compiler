# Simple C Compiler

This project is a simple C compiler that demonstrates the classic compiler components (lexical analysis, parsing, semantic actions, and code generation). The compiler uses Flex to generate the scanner and Yacc to generate the parser. Code generation and symbol table management are implemented in C using supporting files such as `table.h` and `expr_type.h`.

## Features

- **Lexical Analysis**: `scanner.l` contains the Flex definitions and rules for tokenizing the input.  
- **Parsing**: `parser.y` contains the Yacc grammar, semantic actions, and code generation routines.  
- **Code Generation**: Translates C-like code into assembly.
    - `table.h`: Defines the symbol table structure and related variables.  
    - `expr_type.h`: Defines the expression data type structure used during parsing and code generation.
    - `main.c`: The entry point of the compiler which calls the code generation routine.
- **Symbol Table**: Manages declarations and scope.
- **Arduino Integration**: Supports functions like digitalWrite and delay.

## Usage
1. Write your C source code.
2. Compile the project using `make`.
3. Run the generated executable to produce an assembly file (e.g., `codegen.S`).
4. Assemble and link the output for your target hardware.
