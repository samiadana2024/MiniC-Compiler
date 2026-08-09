%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int lexer_error = 0;

extern int yylex();
extern int yylineno;
extern FILE *yyin;

void yyerror(const char *s);
void print_format_string(const char *format);

/* =========================================================
   VARIABLE TABLE
   ========================================================= */

int variables[100];
char variable_names[100][50];
int variable_count = 0;


int get_variable(const char *name)
{
    for (int i = 0; i < variable_count; i++)
    {
        if (strcmp(variable_names[i], name) == 0)
        {
            return variables[i];
        }
    }

    return 0;
}


void set_variable(const char *name, int value)
{
    for (int i = 0; i < variable_count; i++)
    {
        if (strcmp(variable_names[i], name) == 0)
        {
            variables[i] = value;
            return;
        }
    }

    if (variable_count < 100)
    {
        strcpy(variable_names[variable_count], name);
        variables[variable_count] = value;
        variable_count++;
    }
}


/* =========================================================
   EXPRESSION AST
   ========================================================= */

typedef enum
{
    EXPR_NUMBER,
    EXPR_VARIABLE,

    EXPR_ADD,
    EXPR_SUB,
    EXPR_MUL,
    EXPR_DIV,

    EXPR_LT,
    EXPR_GT,
    EXPR_LE,
    EXPR_GE,
    EXPR_EQ,
    EXPR_NEQ

} ExprType;


typedef struct Expr
{
    ExprType type;

    int value;

    char *name;

    struct Expr *left;
    struct Expr *right;

} Expr;


/* =========================================================
   STATEMENT AST
   ========================================================= */

typedef enum
{
    STMT_EMPTY,
    STMT_DECLARATION,
    STMT_ASSIGNMENT,
    STMT_RETURN,
    STMT_PRINTF,
    STMT_BLOCK,
    STMT_IF,
    STMT_WHILE,
    STMT_FOR
} StmtType;


typedef struct Statement Statement;


struct Statement
{
    StmtType type;

    char *name;

    Expr *expr;

    Expr *condition;

    Statement *body;

    Statement *else_body;

    /* FOR loop */
    Statement *for_init;
    Statement *for_update;

    /* Next statement in a list */
    Statement *next;
};


/* =========================================================
   AST CREATION FUNCTIONS
   ========================================================= */

Expr *create_number(int value)
{
    Expr *expr = malloc(sizeof(Expr));

    expr->type = EXPR_NUMBER;
    expr->value = value;

    expr->name = NULL;

    expr->left = NULL;
    expr->right = NULL;

    return expr;
}


Expr *create_variable(char *name)
{
    Expr *expr = malloc(sizeof(Expr));

    expr->type = EXPR_VARIABLE;

    expr->value = 0;

    expr->name = strdup(name);

    expr->left = NULL;
    expr->right = NULL;

    return expr;
}


Expr *create_binary(
    ExprType type,
    Expr *left,
    Expr *right
)
{
    Expr *expr = malloc(sizeof(Expr));

    expr->type = type;

    expr->value = 0;

    expr->name = NULL;

    expr->left = left;
    expr->right = right;

    return expr;
}


Statement *create_statement(StmtType type)
{
    Statement *stmt = malloc(sizeof(Statement));

    stmt->type = type;

    stmt->name = NULL;

    stmt->expr = NULL;

    stmt->condition = NULL;

    stmt->body = NULL;

    stmt->else_body = NULL;

    stmt->for_init = NULL;

    stmt->for_update = NULL;

    stmt->next = NULL;

    return stmt;
}


Statement *append_statement(
    Statement *list,
    Statement *stmt
)
{
    if (list == NULL)
    {
        return stmt;
    }

    Statement *current = list;

    while (current->next != NULL)
    {
        current = current->next;
    }

    current->next = stmt;

    return list;
}


/* =========================================================
   EXPRESSION EVALUATION
   ========================================================= */

int evaluate_expression(Expr *expr)
{
    if (expr == NULL)
    {
        return 0;
    }

    switch (expr->type)
    {
        case EXPR_NUMBER:

            return expr->value;


        case EXPR_VARIABLE:

            return get_variable(expr->name);


        case EXPR_ADD:

            return evaluate_expression(expr->left)
                 + evaluate_expression(expr->right);


        case EXPR_SUB:

            return evaluate_expression(expr->left)
                 - evaluate_expression(expr->right);


        case EXPR_MUL:

            return evaluate_expression(expr->left)
                 * evaluate_expression(expr->right);


        case EXPR_DIV:
        {
            int right =
                evaluate_expression(expr->right);

            if (right == 0)
            {
                fprintf(
                    stderr,
                    "Runtime Error: Division by zero\n"
                );

                return 0;
            }

            return evaluate_expression(expr->left)
                 / right;
        }


        case EXPR_LT:

            return evaluate_expression(expr->left)
                 < evaluate_expression(expr->right);


        case EXPR_GT:

            return evaluate_expression(expr->left)
                 > evaluate_expression(expr->right);


        case EXPR_LE:

            return evaluate_expression(expr->left)
                 <= evaluate_expression(expr->right);


        case EXPR_GE:

            return evaluate_expression(expr->left)
                 >= evaluate_expression(expr->right);


        case EXPR_EQ:

            return evaluate_expression(expr->left)
                 == evaluate_expression(expr->right);


        case EXPR_NEQ:

            return evaluate_expression(expr->left)
                 != evaluate_expression(expr->right);
    }

    return 0;
}


/* =========================================================
   EXECUTION RESULT
   ========================================================= */

typedef struct
{
    int returned;

    int return_value;

} ExecutionResult;


ExecutionResult execute_statements(Statement *stmt);


/* =========================================================
   EXECUTE ONE STATEMENT
   ========================================================= */

ExecutionResult execute_statement(Statement *stmt)
{
    ExecutionResult result;

    result.returned = 0;
    result.return_value = 0;


    if (stmt == NULL)
    {
        return result;
    }


    switch (stmt->type)
    {

        /* -------------------------------------------------
           EMPTY
           ------------------------------------------------- */

        case STMT_EMPTY:

            break;


        /* -------------------------------------------------
           DECLARATION
           ------------------------------------------------- */

        case STMT_DECLARATION:

            if (stmt->expr != NULL)
            {
                set_variable(
                    stmt->name,
                    evaluate_expression(stmt->expr)
                );
            }
            else
            {
                set_variable(
                    stmt->name,
                    0
                );
            }

            break;


        /* -------------------------------------------------
           ASSIGNMENT
           ------------------------------------------------- */

        case STMT_ASSIGNMENT:

            set_variable(
                stmt->name,
                evaluate_expression(stmt->expr)
            );

            break;


        /* -------------------------------------------------
           RETURN
           ------------------------------------------------- */

        case STMT_RETURN:

            result.returned = 1;

            if (stmt->expr != NULL)
            {
                result.return_value =
                    evaluate_expression(stmt->expr);
            }
            else
            {
                result.return_value = 0;
            }

            printf(
                "PROGRAM_OUTPUT: %d\n",
                result.return_value
            );

            break;
/* -------------------------------------------------
   PRINTF
   ------------------------------------------------- */

case STMT_PRINTF:
{
    if (stmt->name != NULL)
    {
        size_t len = strlen(stmt->name);

        if (len >= 2 &&
            stmt->name[0] == '"' &&
            stmt->name[len - 1] == '"')
        {
            /* Remove surrounding quotes */
            stmt->name[len - 1] = '\0';

            char *format = stmt->name + 1;

            /*
             * printf("Hello");
             */
            if (stmt->expr == NULL)
            {
                print_format_string(format);
            }

            /*
             * printf("Value = %d", a);
             */
            else
            {
                int value =
                    evaluate_expression(stmt->expr);

                char *percent =
                    strstr(format, "%d");

                if (percent != NULL)
                {
                    /*
                     * Print text before %d
                     */
                    size_t before_len =
                        percent - format;

                    char before[1024];

                    if (before_len >= sizeof(before))
                    {
                        before_len = sizeof(before) - 1;
                    }

                    strncpy(
                        before,
                        format,
                        before_len
                    );

                    before[before_len] = '\0';

                    print_format_string(before);

                    /*
                     * Print integer value
                     */
                    printf("%d", value);

                    /*
                     * Print text after %d
                     */
                    print_format_string(percent + 2);
                }
                else
                {
                    /*
                     * No %d found.
                     * Just print the string.
                     */
                    print_format_string(format);
                }
            }
        }
    }

    break;
}
        /* -------------------------------------------------
           BLOCK
           ------------------------------------------------- */

        case STMT_BLOCK:

            return execute_statements(stmt->body);


        /* -------------------------------------------------
           IF / ELSE
           ------------------------------------------------- */

        case STMT_IF:
        {
            int condition =
                evaluate_expression(stmt->condition);


            if (condition)
            {
                return execute_statements(
                    stmt->body
                );
            }

            else if (stmt->else_body != NULL)
            {
                return execute_statements(
                    stmt->else_body
                );
            }

            break;
        }


        /* -------------------------------------------------
           WHILE LOOP
           ------------------------------------------------- */

        case STMT_WHILE:
        {
            int iterations = 0;

            const int MAX_ITERATIONS = 100000;


            while (
                evaluate_expression(
                    stmt->condition
                )
            )
            {

                if (iterations >= MAX_ITERATIONS)
                {
                    fprintf(
                        stderr,
                        "Runtime Error: Possible infinite loop "
                        "(maximum 100000 iterations reached)\n"
                    );

                    break;
                }


                ExecutionResult loop_result =
                    execute_statements(
                        stmt->body
                    );


                if (loop_result.returned)
                {
                    return loop_result;
                }


                iterations++;
            }

            break;
        }


        /* -------------------------------------------------
           FOR LOOP
           ------------------------------------------------- */

        case STMT_FOR:
        {
            int iterations = 0;

            const int MAX_ITERATIONS = 100000;


            /* Initialization */

            if (stmt->for_init != NULL)
            {
                ExecutionResult init_result =
                    execute_statement(
                        stmt->for_init
                    );


                if (init_result.returned)
                {
                    return init_result;
                }
            }


            /* Condition + Body + Update */

            while (
                stmt->condition == NULL ||
                evaluate_expression(
                    stmt->condition
                )
            )
            {

                if (iterations >= MAX_ITERATIONS)
                {
                    fprintf(
                        stderr,
                        "Runtime Error: Possible infinite loop "
                        "(maximum 100000 iterations reached)\n"
                    );

                    break;
                }


                /* Execute body */

                ExecutionResult body_result =
                    execute_statements(
                        stmt->body
                    );


                if (body_result.returned)
                {
                    return body_result;
                }


                /* Execute update */

                if (stmt->for_update != NULL)
                {
                    ExecutionResult update_result =
                        execute_statement(
                            stmt->for_update
                        );


                    if (update_result.returned)
                    {
                        return update_result;
                    }
                }


                iterations++;
            }

            break;
        }

    }


    return result;
}
void print_format_string(const char *format)
{
    for (int i = 0; format[i] != '\0'; i++)
    {
        if (format[i] == '\\')
        {
            i++;

            if (format[i] == 'n')
            {
                putchar('\n');
            }
            else if (format[i] == 't')
            {
                putchar('\t');
            }
            else if (format[i] == '\\')
            {
                putchar('\\');
            }
            else if (format[i] == '"')
            {
                putchar('"');
            }
            else
            {
                putchar('\\');

                if (format[i] != '\0')
                {
                    putchar(format[i]);
                }
            }
        }
        else
        {
            putchar(format[i]);
        }
    }
}

/* =========================================================
   EXECUTE STATEMENT LIST
   ========================================================= */

ExecutionResult execute_statements(Statement *stmt)
{
    ExecutionResult result;

    result.returned = 0;
    result.return_value = 0;


    while (stmt != NULL)
    {

        result =
            execute_statement(stmt);


        if (result.returned)
        {
            return result;
        }


        stmt = stmt->next;
    }


    return result;
}


/* =========================================================
   BISON
   ========================================================= */

%}


/*
   These declarations are placed into parser.tab.h.
   They allow the %union below to use Expr* and Statement*.
*/

%code requires
{
    typedef struct Expr Expr;
    typedef struct Statement Statement;
}


%union
{
    int number;

    char *identifier;

    Expr *expr;

    Statement *stmt;
}


/* =========================================================
   TOKENS
   ========================================================= */

%token INT
%token RETURN
%token PRINTF

%token IF
%token ELSE
%token WHILE
%token FOR

%token LEXICAL_ERROR


%token <identifier> IDENTIFIER
%token <identifier> STRING

%token <number> NUMBER

%token SEMI
%token COMMA

%token PLUS
%token MINUS
%token MUL
%token DIV

%token ASSIGN

%token LT
%token GT
%token LE
%token GE
%token EQ
%token NEQ

%token LBRACE
%token RBRACE

%token LPAREN
%token RPAREN


/* =========================================================
   NON-TERMINAL TYPES
   ========================================================= */

%type <stmt> function

%type <stmt> statement
%type <stmt> statements

%type <stmt> block

%type <stmt> declaration
%type <stmt> assignment
%type <stmt> return_stmt
%type <stmt> printf_stmt
%type <stmt> if_stmt
%type <stmt> while_stmt

%type <stmt> for_stmt
%type <stmt> for_init
%type <stmt> for_update


%type <expr> expression
%type <expr> term


/* =========================================================
   OPERATOR PRECEDENCE
   ========================================================= */

%left LT GT LE GE EQ NEQ

%left PLUS MINUS

%left MUL DIV


%%


/* =========================================================
   PROGRAM
   ========================================================= */

program:
    function
    {
        if (!lexer_error)
        {
            ExecutionResult result =
                execute_statements($1);

            (void)result;
        }
    }
;


/* =========================================================
   FUNCTION
   ========================================================= */

function:
    INT IDENTIFIER LPAREN RPAREN block
    {
        $$ = $5;
    }
;


/* =========================================================
   STATEMENTS
   ========================================================= */

statements:
    statement
    {
        $$ = $1;
    }

    | statements statement
    {
        $$ = append_statement(
            $1,
            $2
        );
    }
;


/* =========================================================
   STATEMENT
   ========================================================= */

statement:

    declaration
    {
        $$ = $1;
    }

    | assignment
    {
        $$ = $1;
    }

    | return_stmt
    {
        $$ = $1;
    }

    | printf_stmt
    {
        $$ = $1;
    }

    | block
    {
        $$ = $1;
    }

    | if_stmt
    {
        $$ = $1;
    }

    | while_stmt
    {
        $$ = $1;
    }

    | for_stmt
    {
        $$ = $1;
    }
;

/* =========================================================
   BLOCK
   ========================================================= */

block:
    LBRACE statements RBRACE
    {
        Statement *stmt =
            create_statement(
                STMT_BLOCK
            );

        stmt->body = $2;

        $$ = stmt;
    }

    | LBRACE RBRACE
    {
        Statement *stmt =
            create_statement(
                STMT_BLOCK
            );

        stmt->body = NULL;

        $$ = stmt;
    }
;


/* =========================================================
   DECLARATION
   ========================================================= */

declaration:

    INT IDENTIFIER SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_DECLARATION
            );

        stmt->name =
            strdup($2);

        stmt->expr = NULL;

        $$ = stmt;
    }


    | INT IDENTIFIER ASSIGN expression SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_DECLARATION
            );

        stmt->name =
            strdup($2);

        stmt->expr = $4;

        $$ = stmt;
    }
;


/* =========================================================
   ASSIGNMENT
   ========================================================= */

assignment:

    IDENTIFIER ASSIGN expression SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_ASSIGNMENT
            );

        stmt->name =
            strdup($1);

        stmt->expr = $3;

        $$ = stmt;
    }
;


/* =========================================================
   RETURN
   ========================================================= */

return_stmt:

    RETURN expression SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_RETURN
            );

        stmt->expr = $2;

        $$ = stmt;
    }


    | RETURN SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_RETURN
            );

        stmt->expr = NULL;

        $$ = stmt;
    }
;
/* =========================================================
   PRINTF
   ========================================================= */

printf_stmt:

    PRINTF LPAREN STRING RPAREN SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_PRINTF
            );

        stmt->name =
            strdup($3);

        stmt->expr = NULL;

        $$ = stmt;
    }

    | PRINTF LPAREN STRING COMMA expression RPAREN SEMI
    {
        Statement *stmt =
            create_statement(
                STMT_PRINTF
            );

        stmt->name =
            strdup($3);

        stmt->expr = $5;

        $$ = stmt;
    }
;

/* =========================================================
   IF / ELSE
   ========================================================= */

if_stmt:

    IF LPAREN expression RPAREN block
    {
        Statement *stmt =
            create_statement(
                STMT_IF
            );

        stmt->condition = $3;

        stmt->body = $5;

        stmt->else_body = NULL;

        $$ = stmt;
    }


    | IF LPAREN expression RPAREN block ELSE block
    {
        Statement *stmt =
            create_statement(
                STMT_IF
            );

        stmt->condition = $3;

        stmt->body = $5;

        stmt->else_body = $7;

        $$ = stmt;
    }
;


/* =========================================================
   WHILE
   ========================================================= */

while_stmt:

    WHILE LPAREN expression RPAREN block
    {
        Statement *stmt =
            create_statement(
                STMT_WHILE
            );

        stmt->condition = $3;

        stmt->body = $5;

        $$ = stmt;
    }
;


/* =========================================================
   FOR LOOP
   ========================================================= */

/*
   Supports:

   for (int i = 1; i <= 5; i = i + 1)

   and:

   for (i = 0; i < 5; i = i + 1)
*/

for_stmt:

    FOR LPAREN
        for_init
        SEMI
        expression
        SEMI
        for_update
    RPAREN
    block

    {
        Statement *stmt =
            create_statement(
                STMT_FOR
            );


        stmt->for_init = $3;

        stmt->condition = $5;

        stmt->for_update = $7;

        stmt->body = $9;


        $$ = stmt;
    }
;


/* =========================================================
   FOR INITIALIZATION
   ========================================================= */

/*
   Example:

   int i = 1

   or:

   i = 0
*/

for_init:

    INT IDENTIFIER ASSIGN expression
    {
        Statement *stmt =
            create_statement(
                STMT_DECLARATION
            );

        stmt->name =
            strdup($2);

        stmt->expr = $4;

        $$ = stmt;
    }


    | IDENTIFIER ASSIGN expression
    {
        Statement *stmt =
            create_statement(
                STMT_ASSIGNMENT
            );

        stmt->name =
            strdup($1);

        stmt->expr = $3;

        $$ = stmt;
    }
;


/* =========================================================
   FOR UPDATE
   ========================================================= */

/*
   Example:

   i = i + 1
*/

for_update:

    IDENTIFIER ASSIGN expression
    {
        Statement *stmt =
            create_statement(
                STMT_ASSIGNMENT
            );

        stmt->name =
            strdup($1);

        stmt->expr = $3;

        $$ = stmt;
    }
;


/* =========================================================
   EXPRESSIONS
   ========================================================= */

expression:

    term
    {
        $$ = $1;
    }


    | expression PLUS expression
    {
        $$ =
            create_binary(
                EXPR_ADD,
                $1,
                $3
            );
    }


    | expression MINUS expression
    {
        $$ =
            create_binary(
                EXPR_SUB,
                $1,
                $3
            );
    }


    | expression MUL expression
    {
        $$ =
            create_binary(
                EXPR_MUL,
                $1,
                $3
            );
    }


    | expression DIV expression
    {
        $$ =
            create_binary(
                EXPR_DIV,
                $1,
                $3
            );
    }


    | expression LT expression
    {
        $$ =
            create_binary(
                EXPR_LT,
                $1,
                $3
            );
    }


    | expression GT expression
    {
        $$ =
            create_binary(
                EXPR_GT,
                $1,
                $3
            );
    }


    | expression LE expression
    {
        $$ =
            create_binary(
                EXPR_LE,
                $1,
                $3
            );
    }


    | expression GE expression
    {
        $$ =
            create_binary(
                EXPR_GE,
                $1,
                $3
            );
    }


    | expression EQ expression
    {
        $$ =
            create_binary(
                EXPR_EQ,
                $1,
                $3
            );
    }


    | expression NEQ expression
    {
        $$ =
            create_binary(
                EXPR_NEQ,
                $1,
                $3
            );
    }
;


/* =========================================================
   TERM
   ========================================================= */

term:

    NUMBER
    {
        $$ =
            create_number($1);
    }


    | IDENTIFIER
    {
        $$ =
            create_variable($1);
    }


    | LPAREN expression RPAREN
    {
        $$ = $2;
    }
;


%%


/* =========================================================
   ERROR HANDLER
   ========================================================= */

void yyerror(const char *s)
{
    fprintf(
        stderr,
        "Syntax Error at line %d: %s\n",
        yylineno,
        s
    );
}


/* =========================================================
   MAIN
   ========================================================= */

int main(int argc, char **argv)
{
    if (argc > 1)
    {
        yyin =
            fopen(
                argv[1],
                "r"
            );


        if (!yyin)
        {
            perror(
                "Error opening file"
            );

            return 1;
        }
    }


    int result =
        yyparse();


    if (yyin)
    {
        fclose(yyin);
    }


    if (lexer_error != 0)
    {
        return 1;
    }


    if (result != 0)
    {
        return 1;
    }


    printf(
        "COMPILATION_SUCCESS\n"
    );


    return 0;
}