# psudo Programming Language

## Project Group Members
* **Yusuf Şamil Üzüm 20230808615**
* **Nazlı Gonca 20220808611**
* **Hanifi Berat Sert 20230808617**

## Name of the Programming Language
The name of our programming language is **psudo**.

## Overview
**psudo** is an imperative and educational programming language designed to be simple, readable, and easy to analyze. It supports typed variable declarations, arithmetic and relational expressions, conditional statements, loops, function definitions and calls, input/output operations, comments, and exception handling.

This project was developed in two stages:
- **Part 1:** Lexical analysis using **Lex/Flex**
- **Part 2:** Syntax analysis and execution using **Yacc/Bison**

In its final version, `psudo` can both parse and execute source programs written in its syntax.

## Supported Features
The current implementation supports the following features:

- Simple statement-by-statement execution
- Comments using `//`
- Variable declarations
- Constant declarations
- Assignments
- Arithmetic expressions: `+`, `-`, `*`, `/`
- Relational expressions: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Conditional statements: `IF`, `ELSEIF`, `ELSE`
- Loops: `WHILE`
- Functions
- Function calls
- Return expressions
- Input / Output
  - `PRINT(...)`
  - `SCAN(...)`
- Exception handling
  - `TRY ... CATCH ... END`
  - `THROW(...)`

## Design Decisions

### 1. Human-readable keywords
The language uses explicit English keywords such as:
- `NUMBER`
- `DECIMAL`
- `TEXT`
- `BOOLEAN`
- `FUNCTION`
- `RETURN`
- `TRY`
- `CATCH`

This makes the language easier to read and understand.

### 2. Explicit type system
All variables are declared with a type. This helps reinforce basic programming language concepts such as static typing and variable declarations.

### 3. Structured block-based syntax
Control structures and function bodies use explicit block delimiters such as:
- `THEN ... END`
- `DO ... END`
- `TRY ... CATCH ... END`

This makes parsing easier and keeps the syntax visually clear.

### 4. Strict statement termination
Simple statements must end with a semicolon `;`.

Examples:
- variable declarations
- assignments
- `PRINT`
- `SCAN`
- `RETURN`
- `THROW`

### 5. AST-based execution
The parser is implemented using an AST-based interpreter design for executable constructs such as:
- expressions
- conditionals
- loops
- functions
- exception handling

This allows the language to both parse and execute programs correctly.

## Syntax Explanation

### Variable Declaration
Variables are declared by specifying the type followed by the identifier.

```psudo
NUMBER x;
DECIMAL radius;
TEXT name;
BOOLEAN ok;
```

Variables may also be initialized during declaration:

```psudo
NUMBER x = 10;
DECIMAL r = 2.5;
TEXT msg = "hello";
BOOLEAN ok = TRUE;
```

### Constant Declaration
Constants are declared with the `CONST` keyword.

```psudo
CONST DECIMAL PI = 3.1415;
CONST TEXT WELCOME = "Hello";
```

### Assignment
Values can be assigned to previously declared non-constant variables.

```psudo
x = 25;
radius = radius + 1.0;
```

### Comments
Single-line comments begin with `//`.

```psudo
// this is a comment
NUMBER x = 5;
```

### Input / Output

#### PRINT
Prints the evaluated result of an expression.

```psudo
PRINT(x);
PRINT("hello");
PRINT(radius * 2);
```

#### SCAN
Reads input into a previously declared variable.

```psudo
SCAN(radius);
```

### Conditional Statements
Conditional logic is written using `IF`, optional `ELSEIF`, optional `ELSE`, and `END`.

```psudo
IF x > 10 THEN
    PRINT("big");
ELSEIF x == 10 THEN
    PRINT("equal");
ELSE
    PRINT("small");
END
```

### Loops
The language supports `WHILE` loops.

```psudo
WHILE x > 0 DO
    PRINT(x);
    x = x - 1;
END
```

### Functions
Functions can be declared with typed parameters.

```psudo
FUNCTION add(NUMBER a, NUMBER b) DO
    NUMBER result = a + b;
    RETURN result;
END
```

### Function Calls
Functions can be called inside expressions.

```psudo
NUMBER z = add(3, 4);
PRINT(z);
```

### Exception Handling
Exceptions are handled using `TRY`, `CATCH`, and `THROW`.

```psudo
TRY
    PRINT("before");
    THROW("SomeError");
    PRINT("after");
CATCH
    PRINT("caught");
END
```

### Boolean Values
Boolean literals are:

```psudo
TRUE
FALSE
```

## Grammar in BNF Form

```bnf
<program>        ::= <statement_list>

<statement_list> ::= <statement>
                   | <statement_list> <statement>

<statement>      ::= <declaration>
                   | <assignment>
                   | <io_stmt>
                   | <if_stmt>
                   | <while_stmt>
                   | <func_decl>
                   | <try_catch_stmt>
                   | <throw_stmt>

<declaration>    ::= <type> <identifier> ";"
                   | <type> <identifier> "=" <expression> ";"
                   | "CONST" <type> <identifier> "=" <expression> ";"

<type>           ::= "NUMBER"
                   | "DECIMAL"
                   | "TEXT"
                   | "BOOLEAN"

<assignment>     ::= <identifier> "=" <expression> ";"

<io_stmt>        ::= "PRINT" "(" <expression> ")" ";"
                   | "SCAN" "(" <identifier> ")" ";"

<if_stmt>        ::= "IF" <expression> "THEN" <statement_list> <elseif_chain> <opt_else> "END"

<elseif_chain>   ::= "ELSEIF" <expression> "THEN" <statement_list> <elseif_chain>
                   | empty

<opt_else>       ::= "ELSE" <statement_list>
                   | empty

<while_stmt>     ::= "WHILE" <expression> "DO" <statement_list> "END"

<func_decl>      ::= "FUNCTION" <identifier> "(" <params> ")" "DO"
                     <statement_list>
                     "RETURN" <expression> ";"
                     "END"

<params>         ::= <param_list>
                   | empty

<param_list>     ::= <type> <identifier>
                   | <param_list> "," <type> <identifier>

<func_call>      ::= <identifier> "(" <args> ")"

<args>           ::= <arg_list>
                   | empty

<arg_list>       ::= <expression>
                   | <arg_list> "," <expression>

<try_catch_stmt> ::= "TRY" <statement_list> "CATCH" <statement_list> "END"

<throw_stmt>     ::= "THROW" "(" <expression> ")" ";"

<expression>     ::= <expression> "+" <expression>
                   | <expression> "-" <expression>
                   | <expression> "*" <expression>
                   | <expression> "/" <expression>
                   | <expression> "==" <expression>
                   | <expression> "!=" <expression>
                   | <expression> "<" <expression>
                   | <expression> ">" <expression>
                   | <expression> "<=" <expression>
                   | <expression> ">=" <expression>
                   | "(" <expression> ")"
                   | <factor>

<factor>         ::= <identifier>
                   | <constant>
                   | <func_call>

<constant>       ::= <int_lit>
                   | <decimal_lit>
                   | <string_lit>
                   | "TRUE"
                   | "FALSE"
```

## Project Structure

- `psudo.l` — lexical analyzer rules written with Flex
- `psudo.y` — parser and interpreter implementation written with Bison
- `Makefile` — build automation file
- `exampleprog1.p` — sample program
- `exampleprog2.p` — sample program
- `exampleprog3.p` — sample program
- `exampleprog4.p` — sample program
- `exampleprog5.p` — sample program
- `exampleprog_final.p` — comprehensive sample program
- `README.md` — project report and language documentation

## How to Compile

Run:

```bash
make
```

To clean generated files:

```bash
make clean
```

## How to Run

Run the interpreter with an input source file:

```bash
./psudo < exampleprog_final.p
```

You can also test other example files:

```bash
./psudo < exampleprog1.p
./psudo < exampleprog2.p
./psudo < exampleprog3.p
./psudo < exampleprog4.p
./psudo < exampleprog5.p
```

## Example Programs
The repository includes multiple example programs to demonstrate the supported features of the language. `exampleprog_final.p` can be used to test all features of the language.

- `exampleprog1.p`
- `exampleprog2.p`
- `exampleprog3.p`
- `exampleprog4.p`
- `exampleprog5.p`
- `exampleprog_final.p`

These example programs are used to test different parts of the language such as:
- declarations and assignments
- arithmetic expressions
- conditionals
- loops
- functions
- exception handling
- input / output

## Notes / Limitations

- Comments are single-line only and begin with `//`
- The language currently supports a limited number of variables and functions due to fixed-size internal tables
- Function parameter count is limited
- The implementation is designed for educational purposes rather than full production language behavior

## Summary
The **psudo** programming language project demonstrates the construction of a small but functional programming language using **Lex/Flex** and **Yacc/Bison**. It includes lexical analysis, parsing, AST-based execution, functions, loops, conditionals, input / output, and exception handling.