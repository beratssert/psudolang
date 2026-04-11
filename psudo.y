%code requires {
    typedef struct Expr Expr;
    typedef struct Stmt Stmt;
    typedef struct ParamList ParamList;
    typedef struct ArgList ArgList;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

extern int yylineno;
extern char *yytext;

typedef enum {
    TYPE_NUMBER,
    TYPE_DECIMAL,
    TYPE_TEXT,
    TYPE_BOOLEAN
} DataType;

typedef struct {
    DataType type;
    int int_val;
    double double_val;
    char *str_val;
    int bool_val;
} Value;

typedef struct {
    int has_throw;
    Value thrown_value;
} ExecResult;

typedef enum {
    EXPR_INT,
    EXPR_DECIMAL,
    EXPR_STRING,
    EXPR_BOOL,
    EXPR_IDENTIFIER,
    EXPR_BINARY,
    EXPR_FUNC_CALL
} ExprType;

typedef enum {
    OP_ADD,
    OP_SUB,
    OP_MUL,
    OP_DIV,
    OP_EQ,
    OP_NEQ,
    OP_LT,
    OP_GT,
    OP_LE,
    OP_GE
} BinOp;

typedef enum {
    STMT_DECL,
    STMT_ASSIGN,
    STMT_PRINT,
    STMT_SCAN,
    STMT_IF,
    STMT_WHILE,
    STMT_FUNC_DECL,
    STMT_TRY_CATCH,
    STMT_THROW
} StmtType;

typedef struct Expr {
    ExprType type;
    union {
        int int_val;
        double double_val;
        char *str_val;
        int bool_val;
        char *identifier;
        struct {
            BinOp op;
            struct Expr *left;
            struct Expr *right;
        } binary;
        struct {
            char *name;
            struct ArgList *args;
        } func_call;
    } data;
} Expr;

typedef struct ParamList {
    int count;
    DataType types[16];
    char *names[16];
} ParamList;

typedef struct ArgList {
    int count;
    Expr *items[16];
} ArgList;

typedef struct Stmt {
    StmtType type;
    struct Stmt *next;

    union {
        struct {
            DataType var_type;
            char *name;
            int is_const;
            Expr *init_expr;
        } decl_stmt;

        struct {
            char *name;
            Expr *expr;
        } assign_stmt;

        struct {
            Expr *expr;
        } print_stmt;

        struct {
            char *name;
        } scan_stmt;

        struct {
            Expr *condition;
            struct Stmt *then_branch;
            struct Stmt *else_branch;
        } if_stmt;

        struct {
            Expr *condition;
            struct Stmt *body;
        } while_stmt;

        struct {
            char *name;
            ParamList *params;
            struct Stmt *body;
            Expr *return_expr;
        } func_decl;

        struct {
            struct Stmt *try_block;
            struct Stmt *catch_block;
        } try_catch_stmt;

        struct {
            Expr *expr;
        } throw_stmt;
    } data;
} Stmt;

typedef struct {
    char name[128];
    DataType declared_type;
    int is_const;
    int initialized;
    Value value;
} Symbol;

typedef struct {
    char name[128];
    int param_count;
    DataType param_types[16];
    char *param_names[16];
    Stmt *body;
    Expr *return_expr;
} FunctionDef;

#define MAX_SYMBOLS 256
#define MAX_FUNCTIONS 64

Symbol symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

FunctionDef function_table[MAX_FUNCTIONS];
int function_count = 0;

Stmt *program_root = NULL;

/* function call içinden gelen throw'u expression tarafına taşımak için */
int runtime_has_throw = 0;
Value runtime_thrown_value;

/* Prototypes */
Expr *make_int_expr(int x);
Expr *make_decimal_expr(double x);
Expr *make_string_expr(const char *s);
Expr *make_bool_expr(int b);
Expr *make_identifier_expr(const char *name);
Expr *make_binary_expr(BinOp op, Expr *left, Expr *right);
Expr *make_func_call_expr(const char *name, ArgList *args);

Stmt *make_decl_stmt(DataType type, const char *name, int is_const, Expr *init_expr);
Stmt *make_assign_stmt(const char *name, Expr *expr);
Stmt *make_print_stmt(Expr *expr);
Stmt *make_scan_stmt(const char *name);
Stmt *make_if_stmt(Expr *condition, Stmt *then_branch, Stmt *else_branch);
Stmt *make_while_stmt(Expr *condition, Stmt *body);
Stmt *make_func_decl_stmt(const char *name, ParamList *params, Stmt *body, Expr *return_expr);
Stmt *make_try_catch_stmt(Stmt *try_block, Stmt *catch_block);
Stmt *make_throw_stmt(Expr *expr);

Stmt *append_stmt(Stmt *list, Stmt *node);
Stmt *attach_else_to_if_chain(Stmt *elseif_chain, Stmt *else_branch);

ParamList *make_param_list_empty(void);
ParamList *make_param_list_single(DataType type, const char *name);
ParamList *append_param(ParamList *list, DataType type, const char *name);

ArgList *make_arg_list_empty(void);
ArgList *make_arg_list_single(Expr *expr);
ArgList *append_arg(ArgList *list, Expr *expr);

Value eval_expr(Expr *expr);
ExecResult exec_stmt_list(Stmt *stmt);
ExecResult exec_stmt(Stmt *stmt);

ExecResult make_normal_result(void);
ExecResult make_throw_result(Value v);

int find_symbol(const char *name);
void declare_symbol_runtime(const char *name, DataType type, int is_const);
void assign_symbol_runtime(const char *name, Value v, int allow_const_init);
Value get_symbol_value_runtime(const char *name);

int find_function(const char *name);
void register_function(const char *name, ParamList *params, Stmt *body, Expr *return_expr);
Value call_function(const char *name, ArgList *args);

int is_numeric(Value v);
int is_truthy(Value v);
void print_value(Value v);
void print_exception(Value v);
char *unquote_string(const char *raw);
Value make_number_value(int x);
Value make_decimal_value(double x);
Value make_text_value(const char *s);
Value make_bool_value(int b);
Value copy_value(Value v);
%}

%union {
    char *str;
    int dtype;
    Expr *expr;
    Stmt *stmt;
    ParamList *params;
    ArgList *args;
}

/* Tokens with values */
%token <str> IDENTIFIER
%token <str> INT_LITERAL
%token <str> DECIMAL_LITERAL
%token <str> STRING_LITERAL

/* Keywords */
%token NUMBER DECIMAL TEXT BOOLEAN CONST
%token IF THEN ELSE ELSEIF END
%token WHILE DO
%token FUNCTION RETURN
%token PRINT SCAN
%token TRUE FALSE
%token TRY CATCH THROW

/* Operators */
%token ASSIGN
%token PLUS MINUS MULTIPLY DIVIDE
%token EQ NEQ LT GT LE GE

/* Punctuation */
%token LPAREN RPAREN COMMA SEMICOLON

%type <dtype> type
%type <stmt> program statement_list statement declaration assignment io_stmt if_stmt while_stmt func_decl try_catch_stmt throw_stmt
%type <stmt> opt_else elseif_chain
%type <expr> expression factor constant func_call
%type <params> params param_list
%type <args> args arg_list

%left EQ NEQ LT GT LE GE
%left PLUS MINUS
%left MULTIPLY DIVIDE

%%

program
    : statement_list
      {
          program_root = $1;
          $$ = $1;
      }
    ;

statement_list
    : statement
      {
          $$ = $1;
      }
    | statement_list statement
      {
          $$ = append_stmt($1, $2);
      }
    ;

statement
    : declaration
    | assignment
    | io_stmt
    | if_stmt
    | while_stmt
    | func_decl
    | try_catch_stmt
    | throw_stmt
    ;

declaration
    : type IDENTIFIER SEMICOLON
      {
          $$ = make_decl_stmt($1, $2, 0, NULL);
          free($2);
      }
    | type IDENTIFIER ASSIGN expression SEMICOLON
      {
          $$ = make_decl_stmt($1, $2, 0, $4);
          free($2);
      }
    | CONST type IDENTIFIER ASSIGN expression SEMICOLON
      {
          $$ = make_decl_stmt($2, $3, 1, $5);
          free($3);
      }
    ;

type
    : NUMBER   { $$ = TYPE_NUMBER; }
    | DECIMAL  { $$ = TYPE_DECIMAL; }
    | TEXT     { $$ = TYPE_TEXT; }
    | BOOLEAN  { $$ = TYPE_BOOLEAN; }
    ;

assignment
    : IDENTIFIER ASSIGN expression SEMICOLON
      {
          $$ = make_assign_stmt($1, $3);
          free($1);
      }
    ;

io_stmt
    : PRINT LPAREN expression RPAREN SEMICOLON
      {
          $$ = make_print_stmt($3);
      }
    | SCAN LPAREN IDENTIFIER RPAREN SEMICOLON
      {
          $$ = make_scan_stmt($3);
          free($3);
      }
    ;

if_stmt
    : IF expression THEN statement_list elseif_chain opt_else END
      {
          Stmt *else_part = attach_else_to_if_chain($5, $6);
          $$ = make_if_stmt($2, $4, else_part);
      }
    ;

elseif_chain
    : /* empty */
      {
          $$ = NULL;
      }
    | ELSEIF expression THEN statement_list elseif_chain
      {
          $$ = make_if_stmt($2, $4, $5);
      }
    ;

opt_else
    : /* empty */
      {
          $$ = NULL;
      }
    | ELSE statement_list
      {
          $$ = $2;
      }
    ;

while_stmt
    : WHILE expression DO statement_list END
      {
          $$ = make_while_stmt($2, $4);
      }
    ;

func_decl
    : FUNCTION IDENTIFIER LPAREN params RPAREN DO statement_list RETURN expression SEMICOLON END
      {
          $$ = make_func_decl_stmt($2, $4, $7, $9);
          free($2);
      }
    ;

try_catch_stmt
    : TRY statement_list CATCH statement_list END
      {
          $$ = make_try_catch_stmt($2, $4);
      }
    ;

throw_stmt
    : THROW LPAREN expression RPAREN SEMICOLON
      {
          $$ = make_throw_stmt($3);
      }
    ;

params
    : /* empty */
      {
          $$ = make_param_list_empty();
      }
    | param_list
      {
          $$ = $1;
      }
    ;

param_list
    : type IDENTIFIER
      {
          $$ = make_param_list_single($1, $2);
          free($2);
      }
    | param_list COMMA type IDENTIFIER
      {
          $$ = append_param($1, $3, $4);
          free($4);
      }
    ;

args
    : /* empty */
      {
          $$ = make_arg_list_empty();
      }
    | arg_list
      {
          $$ = $1;
      }
    ;

arg_list
    : expression
      {
          $$ = make_arg_list_single($1);
      }
    | arg_list COMMA expression
      {
          $$ = append_arg($1, $3);
      }
    ;

func_call
    : IDENTIFIER LPAREN args RPAREN
      {
          $$ = make_func_call_expr($1, $3);
          free($1);
      }
    ;

expression
    : expression PLUS expression
      {
          $$ = make_binary_expr(OP_ADD, $1, $3);
      }
    | expression MINUS expression
      {
          $$ = make_binary_expr(OP_SUB, $1, $3);
      }
    | expression MULTIPLY expression
      {
          $$ = make_binary_expr(OP_MUL, $1, $3);
      }
    | expression DIVIDE expression
      {
          $$ = make_binary_expr(OP_DIV, $1, $3);
      }
    | expression EQ expression
      {
          $$ = make_binary_expr(OP_EQ, $1, $3);
      }
    | expression NEQ expression
      {
          $$ = make_binary_expr(OP_NEQ, $1, $3);
      }
    | expression LT expression
      {
          $$ = make_binary_expr(OP_LT, $1, $3);
      }
    | expression GT expression
      {
          $$ = make_binary_expr(OP_GT, $1, $3);
      }
    | expression LE expression
      {
          $$ = make_binary_expr(OP_LE, $1, $3);
      }
    | expression GE expression
      {
          $$ = make_binary_expr(OP_GE, $1, $3);
      }
    | LPAREN expression RPAREN
      {
          $$ = $2;
      }
    | factor
      {
          $$ = $1;
      }
    ;

factor
    : IDENTIFIER
      {
          $$ = make_identifier_expr($1);
          free($1);
      }
    | constant
      {
          $$ = $1;
      }
    | func_call
      {
          $$ = $1;
      }
    ;

constant
    : INT_LITERAL
      {
          $$ = make_int_expr(atoi($1));
          free($1);
      }
    | DECIMAL_LITERAL
      {
          $$ = make_decimal_expr(atof($1));
          free($1);
      }
    | STRING_LITERAL
      {
          char *tmp = unquote_string($1);
          $$ = make_string_expr(tmp);
          free(tmp);
          free($1);
      }
    | TRUE
      {
          $$ = make_bool_expr(1);
      }
    | FALSE
      {
          $$ = make_bool_expr(0);
      }
    ;

%%

Expr *make_int_expr(int x) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_INT;
    e->data.int_val = x;
    return e;
}

Expr *make_decimal_expr(double x) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_DECIMAL;
    e->data.double_val = x;
    return e;
}

Expr *make_string_expr(const char *s) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_STRING;
    e->data.str_val = strdup(s);
    return e;
}

Expr *make_bool_expr(int b) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_BOOL;
    e->data.bool_val = b ? 1 : 0;
    return e;
}

Expr *make_identifier_expr(const char *name) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_IDENTIFIER;
    e->data.identifier = strdup(name);
    return e;
}

Expr *make_binary_expr(BinOp op, Expr *left, Expr *right) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_BINARY;
    e->data.binary.op = op;
    e->data.binary.left = left;
    e->data.binary.right = right;
    return e;
}

Expr *make_func_call_expr(const char *name, ArgList *args) {
    Expr *e = (Expr *)malloc(sizeof(Expr));
    e->type = EXPR_FUNC_CALL;
    e->data.func_call.name = strdup(name);
    e->data.func_call.args = args;
    return e;
}

Stmt *make_decl_stmt(DataType type, const char *name, int is_const, Expr *init_expr) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_DECL;
    s->next = NULL;
    s->data.decl_stmt.var_type = type;
    s->data.decl_stmt.name = strdup(name);
    s->data.decl_stmt.is_const = is_const;
    s->data.decl_stmt.init_expr = init_expr;
    return s;
}

Stmt *make_assign_stmt(const char *name, Expr *expr) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_ASSIGN;
    s->next = NULL;
    s->data.assign_stmt.name = strdup(name);
    s->data.assign_stmt.expr = expr;
    return s;
}

Stmt *make_print_stmt(Expr *expr) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_PRINT;
    s->next = NULL;
    s->data.print_stmt.expr = expr;
    return s;
}

Stmt *make_scan_stmt(const char *name) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_SCAN;
    s->next = NULL;
    s->data.scan_stmt.name = strdup(name);
    return s;
}

Stmt *make_if_stmt(Expr *condition, Stmt *then_branch, Stmt *else_branch) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_IF;
    s->next = NULL;
    s->data.if_stmt.condition = condition;
    s->data.if_stmt.then_branch = then_branch;
    s->data.if_stmt.else_branch = else_branch;
    return s;
}

Stmt *make_while_stmt(Expr *condition, Stmt *body) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_WHILE;
    s->next = NULL;
    s->data.while_stmt.condition = condition;
    s->data.while_stmt.body = body;
    return s;
}

Stmt *make_func_decl_stmt(const char *name, ParamList *params, Stmt *body, Expr *return_expr) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_FUNC_DECL;
    s->next = NULL;
    s->data.func_decl.name = strdup(name);
    s->data.func_decl.params = params;
    s->data.func_decl.body = body;
    s->data.func_decl.return_expr = return_expr;
    return s;
}

Stmt *make_try_catch_stmt(Stmt *try_block, Stmt *catch_block) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_TRY_CATCH;
    s->next = NULL;
    s->data.try_catch_stmt.try_block = try_block;
    s->data.try_catch_stmt.catch_block = catch_block;
    return s;
}

Stmt *make_throw_stmt(Expr *expr) {
    Stmt *s = (Stmt *)malloc(sizeof(Stmt));
    s->type = STMT_THROW;
    s->next = NULL;
    s->data.throw_stmt.expr = expr;
    return s;
}

Stmt *append_stmt(Stmt *list, Stmt *node) {
    if (list == NULL) return node;
    Stmt *curr = list;
    while (curr->next != NULL) curr = curr->next;
    curr->next = node;
    return list;
}

Stmt *attach_else_to_if_chain(Stmt *elseif_chain, Stmt *else_branch) {
    if (elseif_chain == NULL) return else_branch;

    Stmt *curr = elseif_chain;
    while (curr->type == STMT_IF &&
           curr->data.if_stmt.else_branch != NULL &&
           curr->data.if_stmt.else_branch->type == STMT_IF) {
        curr = curr->data.if_stmt.else_branch;
    }

    if (curr->type == STMT_IF && curr->data.if_stmt.else_branch == NULL) {
        curr->data.if_stmt.else_branch = else_branch;
    }

    return elseif_chain;
}

ParamList *make_param_list_empty(void) {
    ParamList *p = (ParamList *)malloc(sizeof(ParamList));
    p->count = 0;
    return p;
}

ParamList *make_param_list_single(DataType type, const char *name) {
    ParamList *p = make_param_list_empty();
    p->types[0] = type;
    p->names[0] = strdup(name);
    p->count = 1;
    return p;
}

ParamList *append_param(ParamList *list, DataType type, const char *name) {
    if (list->count >= 16) {
        fprintf(stderr, "Semantic error: too many parameters\n");
        exit(1);
    }
    list->types[list->count] = type;
    list->names[list->count] = strdup(name);
    list->count++;
    return list;
}

ArgList *make_arg_list_empty(void) {
    ArgList *a = (ArgList *)malloc(sizeof(ArgList));
    a->count = 0;
    return a;
}

ArgList *make_arg_list_single(Expr *expr) {
    ArgList *a = make_arg_list_empty();
    a->items[0] = expr;
    a->count = 1;
    return a;
}

ArgList *append_arg(ArgList *list, Expr *expr) {
    if (list->count >= 16) {
        fprintf(stderr, "Semantic error: too many arguments\n");
        exit(1);
    }
    list->items[list->count] = expr;
    list->count++;
    return list;
}

Value make_number_value(int x) {
    Value v;
    v.type = TYPE_NUMBER;
    v.int_val = x;
    v.double_val = (double)x;
    v.str_val = NULL;
    v.bool_val = (x != 0);
    return v;
}

Value make_decimal_value(double x) {
    Value v;
    v.type = TYPE_DECIMAL;
    v.int_val = (int)x;
    v.double_val = x;
    v.str_val = NULL;
    v.bool_val = (x != 0.0);
    return v;
}

Value make_text_value(const char *s) {
    Value v;
    v.type = TYPE_TEXT;
    v.int_val = 0;
    v.double_val = 0.0;
    v.str_val = strdup(s);
    v.bool_val = 0;
    return v;
}

Value make_bool_value(int b) {
    Value v;
    v.type = TYPE_BOOLEAN;
    v.int_val = b ? 1 : 0;
    v.double_val = (double)(b ? 1 : 0);
    v.str_val = NULL;
    v.bool_val = b ? 1 : 0;
    return v;
}

Value copy_value(Value v) {
    Value out = v;
    if (v.type == TYPE_TEXT && v.str_val != NULL) {
        out.str_val = strdup(v.str_val);
    }
    return out;
}

ExecResult make_normal_result(void) {
    ExecResult r;
    r.has_throw = 0;
    return r;
}

ExecResult make_throw_result(Value v) {
    ExecResult r;
    r.has_throw = 1;
    r.thrown_value = copy_value(v);
    return r;
}

int is_numeric(Value v) {
    return v.type == TYPE_NUMBER || v.type == TYPE_DECIMAL;
}

int is_truthy(Value v) {
    if (v.type == TYPE_BOOLEAN) return v.bool_val;
    if (v.type == TYPE_NUMBER) return v.int_val != 0;
    if (v.type == TYPE_DECIMAL) return v.double_val != 0.0;

    fprintf(stderr, "Runtime error: condition must be BOOLEAN or numeric\n");
    exit(1);
}

void print_value(Value v) {
    switch (v.type) {
        case TYPE_NUMBER:
            printf("%d\n", v.int_val);
            break;
        case TYPE_DECIMAL:
            printf("%g\n", v.double_val);
            break;
        case TYPE_TEXT:
            printf("%s\n", v.str_val);
            break;
        case TYPE_BOOLEAN:
            printf("%s\n", v.bool_val ? "TRUE" : "FALSE");
            break;
    }
}

void print_exception(Value v) {
    fprintf(stderr, "Unhandled exception: ");
    switch (v.type) {
        case TYPE_NUMBER:
            fprintf(stderr, "%d\n", v.int_val);
            break;
        case TYPE_DECIMAL:
            fprintf(stderr, "%g\n", v.double_val);
            break;
        case TYPE_TEXT:
            fprintf(stderr, "%s\n", v.str_val);
            break;
        case TYPE_BOOLEAN:
            fprintf(stderr, "%s\n", v.bool_val ? "TRUE" : "FALSE");
            break;
    }
}

int find_symbol(const char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) return i;
    }
    return -1;
}

void declare_symbol_runtime(const char *name, DataType type, int is_const) {
    if (find_symbol(name) != -1) {
        fprintf(stderr, "Semantic error: variable '%s' already declared\n", name);
        exit(1);
    }

    if (symbol_count >= MAX_SYMBOLS) {
        fprintf(stderr, "Semantic error: symbol table overflow\n");
        exit(1);
    }

    strcpy(symbol_table[symbol_count].name, name);
    symbol_table[symbol_count].declared_type = type;
    symbol_table[symbol_count].is_const = is_const;
    symbol_table[symbol_count].initialized = 0;
    symbol_table[symbol_count].value.type = type;
    symbol_table[symbol_count].value.int_val = 0;
    symbol_table[symbol_count].value.double_val = 0.0;
    symbol_table[symbol_count].value.str_val = NULL;
    symbol_table[symbol_count].value.bool_val = 0;

    symbol_count++;
}

void assign_symbol_runtime(const char *name, Value v, int allow_const_init) {
    int idx = find_symbol(name);
    if (idx == -1) {
        fprintf(stderr, "Semantic error: variable '%s' not declared\n", name);
        exit(1);
    }

    if (symbol_table[idx].is_const && !allow_const_init) {
        fprintf(stderr, "Semantic error: cannot assign to const variable '%s'\n", name);
        exit(1);
    }

    DataType target = symbol_table[idx].declared_type;

    if (target == TYPE_NUMBER) {
        if (v.type == TYPE_NUMBER) {
            symbol_table[idx].value = make_number_value(v.int_val);
        } else if (v.type == TYPE_DECIMAL) {
            symbol_table[idx].value = make_number_value((int)v.double_val);
        } else {
            fprintf(stderr, "Type error: incompatible assignment to NUMBER '%s'\n", name);
            exit(1);
        }
    } else if (target == TYPE_DECIMAL) {
        if (v.type == TYPE_NUMBER) {
            symbol_table[idx].value = make_decimal_value((double)v.int_val);
        } else if (v.type == TYPE_DECIMAL) {
            symbol_table[idx].value = make_decimal_value(v.double_val);
        } else {
            fprintf(stderr, "Type error: incompatible assignment to DECIMAL '%s'\n", name);
            exit(1);
        }
    } else if (target == TYPE_TEXT) {
        if (v.type != TYPE_TEXT) {
            fprintf(stderr, "Type error: incompatible assignment to TEXT '%s'\n", name);
            exit(1);
        }
        symbol_table[idx].value = make_text_value(v.str_val);
    } else if (target == TYPE_BOOLEAN) {
        if (v.type == TYPE_BOOLEAN) {
            symbol_table[idx].value = make_bool_value(v.bool_val);
        } else if (v.type == TYPE_NUMBER) {
            symbol_table[idx].value = make_bool_value(v.int_val != 0);
        } else if (v.type == TYPE_DECIMAL) {
            symbol_table[idx].value = make_bool_value(v.double_val != 0.0);
        } else {
            fprintf(stderr, "Type error: incompatible assignment to BOOLEAN '%s'\n", name);
            exit(1);
        }
    }

    symbol_table[idx].initialized = 1;
}

Value get_symbol_value_runtime(const char *name) {
    int idx = find_symbol(name);
    if (idx == -1) {
        fprintf(stderr, "Semantic error: variable '%s' not declared\n", name);
        exit(1);
    }

    if (!symbol_table[idx].initialized) {
        fprintf(stderr, "Semantic error: variable '%s' used before initialization\n", name);
        exit(1);
    }

    return copy_value(symbol_table[idx].value);
}

int find_function(const char *name) {
    for (int i = 0; i < function_count; i++) {
        if (strcmp(function_table[i].name, name) == 0) return i;
    }
    return -1;
}

void register_function(const char *name, ParamList *params, Stmt *body, Expr *return_expr) {
    if (find_function(name) != -1) {
        fprintf(stderr, "Semantic error: function '%s' already declared\n", name);
        exit(1);
    }

    if (function_count >= MAX_FUNCTIONS) {
        fprintf(stderr, "Semantic error: function table overflow\n");
        exit(1);
    }

    strcpy(function_table[function_count].name, name);
    function_table[function_count].param_count = params ? params->count : 0;

    for (int i = 0; i < function_table[function_count].param_count; i++) {
        function_table[function_count].param_types[i] = params->types[i];
        function_table[function_count].param_names[i] = strdup(params->names[i]);
    }

    function_table[function_count].body = body;
    function_table[function_count].return_expr = return_expr;
    function_count++;
}

Value call_function(const char *name, ArgList *args) {
    int idx = find_function(name);
    if (idx == -1) {
        fprintf(stderr, "Semantic error: function '%s' not declared\n", name);
        exit(1);
    }

    FunctionDef *fn = &function_table[idx];
    int arg_count = args ? args->count : 0;

    if (arg_count != fn->param_count) {
        fprintf(stderr, "Semantic error: function '%s' expects %d arguments, got %d\n",
                name, fn->param_count, arg_count);
        exit(1);
    }

    Value arg_values[16];
    for (int i = 0; i < arg_count; i++) {
        arg_values[i] = eval_expr(args->items[i]);
        if (runtime_has_throw) {
            return make_number_value(0);
        }
    }

    Symbol saved_symbols[MAX_SYMBOLS];
    int saved_symbol_count = symbol_count;

    for (int i = 0; i < symbol_count; i++) {
        saved_symbols[i] = symbol_table[i];
        if (saved_symbols[i].value.type == TYPE_TEXT && saved_symbols[i].value.str_val != NULL) {
            saved_symbols[i].value.str_val = strdup(saved_symbols[i].value.str_val);
        }
    }

    for (int i = 0; i < fn->param_count; i++) {
        declare_symbol_runtime(fn->param_names[i], fn->param_types[i], 0);
        assign_symbol_runtime(fn->param_names[i], arg_values[i], 1);
    }

    ExecResult body_result = exec_stmt_list(fn->body);

    Value ret = make_number_value(0);
    if (body_result.has_throw) {
        runtime_has_throw = 1;
        runtime_thrown_value = copy_value(body_result.thrown_value);
    } else {
        ret = eval_expr(fn->return_expr);
    }

    for (int i = 0; i < symbol_count; i++) {
        if (symbol_table[i].value.type == TYPE_TEXT && symbol_table[i].value.str_val != NULL) {
            free(symbol_table[i].value.str_val);
        }
    }

    symbol_count = saved_symbol_count;
    for (int i = 0; i < saved_symbol_count; i++) {
        symbol_table[i] = saved_symbols[i];
    }

    return ret;
}

Value eval_expr(Expr *expr) {
    if (expr == NULL) {
        fprintf(stderr, "Internal error: null expression\n");
        exit(1);
    }

    switch (expr->type) {
        case EXPR_INT:
            return make_number_value(expr->data.int_val);

        case EXPR_DECIMAL:
            return make_decimal_value(expr->data.double_val);

        case EXPR_STRING:
            return make_text_value(expr->data.str_val);

        case EXPR_BOOL:
            return make_bool_value(expr->data.bool_val);

        case EXPR_IDENTIFIER:
            return get_symbol_value_runtime(expr->data.identifier);

        case EXPR_FUNC_CALL:
            return call_function(expr->data.func_call.name, expr->data.func_call.args);

        case EXPR_BINARY: {
            Value left = eval_expr(expr->data.binary.left);
            if (runtime_has_throw) return make_number_value(0);

            Value right = eval_expr(expr->data.binary.right);
            if (runtime_has_throw) return make_number_value(0);

            switch (expr->data.binary.op) {
                case OP_ADD:
                    if (!is_numeric(left) || !is_numeric(right)) {
                        fprintf(stderr, "Type error: '+' requires numeric operands\n");
                        exit(1);
                    }
                    if (left.type == TYPE_NUMBER && right.type == TYPE_NUMBER) {
                        return make_number_value(left.int_val + right.int_val);
                    }
                    return make_decimal_value(
                        (left.type == TYPE_DECIMAL ? left.double_val : left.int_val) +
                        (right.type == TYPE_DECIMAL ? right.double_val : right.int_val)
                    );

                case OP_SUB:
                    if (!is_numeric(left) || !is_numeric(right)) {
                        fprintf(stderr, "Type error: '-' requires numeric operands\n");
                        exit(1);
                    }
                    if (left.type == TYPE_NUMBER && right.type == TYPE_NUMBER) {
                        return make_number_value(left.int_val - right.int_val);
                    }
                    return make_decimal_value(
                        (left.type == TYPE_DECIMAL ? left.double_val : left.int_val) -
                        (right.type == TYPE_DECIMAL ? right.double_val : right.int_val)
                    );

                case OP_MUL:
                    if (!is_numeric(left) || !is_numeric(right)) {
                        fprintf(stderr, "Type error: '*' requires numeric operands\n");
                        exit(1);
                    }
                    if (left.type == TYPE_NUMBER && right.type == TYPE_NUMBER) {
                        return make_number_value(left.int_val * right.int_val);
                    }
                    return make_decimal_value(
                        (left.type == TYPE_DECIMAL ? left.double_val : left.int_val) *
                        (right.type == TYPE_DECIMAL ? right.double_val : right.int_val)
                    );

                case OP_DIV: {
                    if (!is_numeric(left) || !is_numeric(right)) {
                        fprintf(stderr, "Type error: '/' requires numeric operands\n");
                        exit(1);
                    }

                    double r = (right.type == TYPE_DECIMAL ? right.double_val : right.int_val);
                    if (r == 0.0) {
                        fprintf(stderr, "Runtime error: division by zero\n");
                        exit(1);
                    }

                    double l = (left.type == TYPE_DECIMAL ? left.double_val : left.int_val);
                    return make_decimal_value(l / r);
                }

                case OP_EQ:
                    if (left.type == TYPE_TEXT && right.type == TYPE_TEXT) {
                        return make_bool_value(strcmp(left.str_val, right.str_val) == 0);
                    }
                    if (is_numeric(left) && is_numeric(right)) {
                        double l = (left.type == TYPE_DECIMAL ? left.double_val : left.int_val);
                        double r = (right.type == TYPE_DECIMAL ? right.double_val : right.int_val);
                        return make_bool_value(l == r);
                    }
                    if (left.type == TYPE_BOOLEAN && right.type == TYPE_BOOLEAN) {
                        return make_bool_value(left.bool_val == right.bool_val);
                    }
                    fprintf(stderr, "Type error: invalid operands for '=='\n");
                    exit(1);

                case OP_NEQ:
                    if (left.type == TYPE_TEXT && right.type == TYPE_TEXT) {
                        return make_bool_value(strcmp(left.str_val, right.str_val) != 0);
                    }
                    if (is_numeric(left) && is_numeric(right)) {
                        double l = (left.type == TYPE_DECIMAL ? left.double_val : left.int_val);
                        double r = (right.type == TYPE_DECIMAL ? right.double_val : right.int_val);
                        return make_bool_value(l != r);
                    }
                    if (left.type == TYPE_BOOLEAN && right.type == TYPE_BOOLEAN) {
                        return make_bool_value(left.bool_val != right.bool_val);
                    }
                    fprintf(stderr, "Type error: invalid operands for '!='\n");
                    exit(1);

                case OP_LT:
                case OP_GT:
                case OP_LE:
                case OP_GE: {
                    if (!is_numeric(left) || !is_numeric(right)) {
                        fprintf(stderr, "Type error: comparison requires numeric operands\n");
                        exit(1);
                    }

                    double l = (left.type == TYPE_DECIMAL ? left.double_val : left.int_val);
                    double r = (right.type == TYPE_DECIMAL ? right.double_val : right.int_val);

                    if (expr->data.binary.op == OP_LT) return make_bool_value(l < r);
                    if (expr->data.binary.op == OP_GT) return make_bool_value(l > r);
                    if (expr->data.binary.op == OP_LE) return make_bool_value(l <= r);
                    return make_bool_value(l >= r);
                }
            }
        }
    }

    fprintf(stderr, "Internal error: unknown expression type\n");
    exit(1);
}

ExecResult exec_stmt_list(Stmt *stmt) {
    Stmt *curr = stmt;
    while (curr != NULL) {
        ExecResult r = exec_stmt(curr);
        if (r.has_throw) return r;
        curr = curr->next;
    }
    return make_normal_result();
}

ExecResult exec_stmt(Stmt *stmt) {
    switch (stmt->type) {
        case STMT_DECL: {
            declare_symbol_runtime(
                stmt->data.decl_stmt.name,
                stmt->data.decl_stmt.var_type,
                stmt->data.decl_stmt.is_const
            );

            if (stmt->data.decl_stmt.init_expr != NULL) {
                Value v = eval_expr(stmt->data.decl_stmt.init_expr);
                if (runtime_has_throw) {
                    runtime_has_throw = 0;
                    return make_throw_result(runtime_thrown_value);
                }
                assign_symbol_runtime(stmt->data.decl_stmt.name, v, 1);
            }
            return make_normal_result();
        }

        case STMT_ASSIGN: {
            Value v = eval_expr(stmt->data.assign_stmt.expr);
            if (runtime_has_throw) {
                runtime_has_throw = 0;
                return make_throw_result(runtime_thrown_value);
            }
            assign_symbol_runtime(stmt->data.assign_stmt.name, v, 0);
            return make_normal_result();
        }

        case STMT_PRINT: {
            Value v = eval_expr(stmt->data.print_stmt.expr);
            if (runtime_has_throw) {
                runtime_has_throw = 0;
                return make_throw_result(runtime_thrown_value);
            }
            print_value(v);
            return make_normal_result();
        }

        case STMT_SCAN: {
            int idx = find_symbol(stmt->data.scan_stmt.name);
            if (idx == -1) {
                fprintf(stderr, "Semantic error: variable '%s' not declared\n", stmt->data.scan_stmt.name);
                exit(1);
            }

            if (symbol_table[idx].is_const) {
                fprintf(stderr, "Semantic error: cannot scan into const variable '%s'\n", stmt->data.scan_stmt.name);
                exit(1);
            }

            if (symbol_table[idx].declared_type == TYPE_NUMBER) {
                int x;
                scanf("%d", &x);
                symbol_table[idx].value = make_number_value(x);
            } else if (symbol_table[idx].declared_type == TYPE_DECIMAL) {
                double d;
                scanf("%lf", &d);
                symbol_table[idx].value = make_decimal_value(d);
            } else if (symbol_table[idx].declared_type == TYPE_BOOLEAN) {
                char buf[32];
                scanf("%31s", buf);
                symbol_table[idx].value = make_bool_value(
                    strcmp(buf, "TRUE") == 0 ||
                    strcmp(buf, "true") == 0 ||
                    strcmp(buf, "1") == 0
                );
            } else if (symbol_table[idx].declared_type == TYPE_TEXT) {
                char buf[1024];
                scanf("%1023s", buf);
                symbol_table[idx].value = make_text_value(buf);
            }

            symbol_table[idx].initialized = 1;
            return make_normal_result();
        }

        case STMT_IF: {
            Value cond = eval_expr(stmt->data.if_stmt.condition);
            if (runtime_has_throw) {
                runtime_has_throw = 0;
                return make_throw_result(runtime_thrown_value);
            }

            if (is_truthy(cond)) {
                return exec_stmt_list(stmt->data.if_stmt.then_branch);
            } else if (stmt->data.if_stmt.else_branch != NULL) {
                return exec_stmt_list(stmt->data.if_stmt.else_branch);
            }
            return make_normal_result();
        }

        case STMT_WHILE: {
            while (1) {
                Value cond = eval_expr(stmt->data.while_stmt.condition);
                if (runtime_has_throw) {
                    runtime_has_throw = 0;
                    return make_throw_result(runtime_thrown_value);
                }

                if (!is_truthy(cond)) break;

                ExecResult body_result = exec_stmt_list(stmt->data.while_stmt.body);
                if (body_result.has_throw) return body_result;
            }
            return make_normal_result();
        }

        case STMT_FUNC_DECL: {
            register_function(
                stmt->data.func_decl.name,
                stmt->data.func_decl.params,
                stmt->data.func_decl.body,
                stmt->data.func_decl.return_expr
            );
            return make_normal_result();
        }

        case STMT_TRY_CATCH: {
            ExecResult try_result = exec_stmt_list(stmt->data.try_catch_stmt.try_block);
            if (try_result.has_throw) {
                return exec_stmt_list(stmt->data.try_catch_stmt.catch_block);
            }
            return make_normal_result();
        }

        case STMT_THROW: {
            Value v = eval_expr(stmt->data.throw_stmt.expr);
            if (runtime_has_throw) {
                runtime_has_throw = 0;
                return make_throw_result(runtime_thrown_value);
            }
            return make_throw_result(v);
        }
    }

    return make_normal_result();
}

char *unquote_string(const char *raw) {
    size_t len = strlen(raw);
    char *result;

    if (len >= 2 && raw[0] == '"' && raw[len - 1] == '"') {
        result = (char *)malloc(len - 1);
        strncpy(result, raw + 1, len - 2);
        result[len - 2] = '\0';
        return result;
    }

    return strdup(raw);
}

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d near '%s': %s\n", yylineno, yytext, s);
}

int main(void) {
    if (yyparse() == 0) {
        ExecResult result = exec_stmt_list(program_root);
        if (result.has_throw) {
            print_exception(result.thrown_value);
            return 1;
        }
    }
    return 0;
}