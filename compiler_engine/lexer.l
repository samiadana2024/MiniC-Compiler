%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int lexer_error;
%}

%option noyywrap
%option yylineno

%%

"int" {
    printf("TOKEN: KEYWORD (int)\n");
    return INT;
}

"return" {
    printf("TOKEN: KEYWORD (return)\n");
    return RETURN;
}

"if" {
    printf("TOKEN: KEYWORD (if)\n");
    return IF;
}

"else" {
    printf("TOKEN: KEYWORD (else)\n");
    return ELSE;
}

"while" {
    printf("TOKEN: KEYWORD (while)\n");
    return WHILE;
}

"for" {
    printf("TOKEN: KEYWORD (for)\n");
    return FOR;
}

"printf" {
    printf("TOKEN: KEYWORD (printf)\n");
    return PRINTF;
}

\/\/[^\n]* {
}

\/\*([^*]|\*+[^*/])*\*+\/ {
}

\"([^\"\\]|\\.)*\" {
    printf("TOKEN: STRING (%s)\n", yytext);
    yylval.identifier = strdup(yytext);
    return STRING;
}

"," {
    printf("TOKEN: PUNCTUATION (,)\n");
    return COMMA;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    printf("TOKEN: IDENTIFIER (%s)\n", yytext);
    yylval.identifier = strdup(yytext);
    return IDENTIFIER;
}

[0-9]+ {
    printf("TOKEN: NUMBER (%s)\n", yytext);
    yylval.number = atoi(yytext);
    return NUMBER;
}

"==" {
printf("TOKEN: OPERATOR (==)\n");
return EQ;
}

"!=" {
printf("TOKEN: OPERATOR (!=)\n");
return NEQ;
}

"<=" {
printf("TOKEN: OPERATOR (<=)\n");
return LE;
}

">=" {
printf("TOKEN: OPERATOR (>=)\n");
return GE;
}

"++" {
printf("TOKEN: OPERATOR (++)\n");
return INC;
}

"--" {
printf("TOKEN: OPERATOR (--)\n");
return DEC;
}

"+" {
printf("TOKEN: OPERATOR (+)\n");
return PLUS;
}

"-" {
printf("TOKEN: OPERATOR (-)\n");
return MINUS;
}
"*" {
    printf("TOKEN: OPERATOR (*)\n");
    return MUL;
}

"/" {
    printf("TOKEN: OPERATOR (/)\n");
    return DIV;
}

"<" {
    printf("TOKEN: OPERATOR (<)\n");
    return LT;
}

">" {
    printf("TOKEN: OPERATOR (>)\n");
    return GT;
}

"=" {
    printf("TOKEN: OPERATOR (=)\n");
    return ASSIGN;
}

";" {
    printf("TOKEN: PUNCTUATION (;)\n");
    return SEMI;
}

"{" {
    printf("TOKEN: PUNCTUATION ({)\n");
    return LBRACE;
}

"}" {
    printf("TOKEN: PUNCTUATION (})\n");
    return RBRACE;
}

"(" {
    printf("TOKEN: PUNCTUATION (()\n");
    return LPAREN;
}

")" {
    printf("TOKEN: PUNCTUATION ())\n");
    return RPAREN;
}

[ \t\r\n]+ {
}

. {
    fprintf(
        stderr,
        "Lexical Error at line %d: Unrecognized character '%s'\n",
        yylineno,
        yytext
    );

    lexer_error = 1;
    return LEXICAL_ERROR;
}

%%