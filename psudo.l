%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TYPE_NUMBER,
    TYPE_DECIMAL,
    TYPE_TEXT,
    TYPE_BOOLEAN,
    TYPE_UNDEF
} DataType;

typedef struct {
    DataType type;
    int is_const;
    int initialized;

    int int_val;
    double double_val;
    char *str_val;
    int bool_val;
} Value;

#include "psudo.tab.h"
%}


%option noyywrap yylineno

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
INT        {DIGIT}+
DECNUM     {DIGIT}+"."{DIGIT}+
STRING     \"([^\\\"\n]|\\.)*\"
COMMENT    "//".*

%%

"NUMBER"        { return NUMBER; }
"DECIMAL"       { return DECIMAL; }
"TEXT"          { return TEXT; }
"BOOLEAN"       { return BOOLEAN; }
"CONST"         { return CONST; }

"IF"            { return IF; }
"THEN"          { return THEN; }
"ELSE"          { return ELSE; }
"ELSEIF"        { return ELSEIF; }
"END"           { return END; }

"WHILE"         { return WHILE; }
"DO"            { return DO; }

"FUNCTION"      { return FUNCTION; }
"RETURN"        { return RETURN; }

"PRINT"         { return PRINT; }
"SCAN"          { return SCAN; }

"TRUE"          { return TRUE; }
"FALSE"         { return FALSE; }

"TRY"           { return TRY; }
"CATCH"         { return CATCH; }
"THROW"         { return THROW; }

{COMMENT}       { }

"=="            { return EQ; }
"!="            { return NEQ; }
"<="            { return LE; }
">="            { return GE; }
"<"             { return LT; }
">"             { return GT; }

"="             { return ASSIGN; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }

"("             { return LPAREN; }
")"             { return RPAREN; }
","             { return COMMA; }
";"             { return SEMICOLON; }

{DECNUM}        {
                    yylval.str = strdup(yytext);
                    return DECIMAL_LITERAL;
                }

{INT}           {
                    yylval.str = strdup(yytext);
                    return INT_LITERAL;
                }

{STRING}        {
                    yylval.str = strdup(yytext);
                    return STRING_LITERAL;
                }

{ID}            {
                    yylval.str = strdup(yytext);
                    return IDENTIFIER;
                }

[ \t\r\n]+      { }

.               {
                    fprintf(stderr, "Lexical error at line %d: invalid character '%s'\n", yylineno, yytext);
                    exit(1);
                }

%%