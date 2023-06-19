%{
    #include "code.h"
    extern int yylex();
    extern int yyerror();
    int debug_err = 0;
    FILE* fptr;
    char filename[100];
    char* err_msg[30] = {
        "Success",
        "Unknown error",
        "Variable is already declared",
        "Variable hasn't been declared",
        "Array hasn't been declared",
        "Expression must be a constant value",
        "Variable type must not be a const type",
        "Parameter must be integer type",
        "Expression must be integer or real type",
        "Expression must be integer type",
        "Expression must be boolean type",
        "Variable must be array type",
        "Variable must be in function type",
        "Variable must be in procedure type",
        "Expression must be scalar type",
        "Index must be of integer type",
        "Index value is too big",
        "Value must be the same type as variable",
        "Array value must have the same size as variable",
        "Result expression type must be the same as function return type",
        "Parameter size is not the same for the given function",
        "Parameter value type does not match for the given function",
        "Function must return value",
        "Function not declared",
        "Expression cannot be function type without proper invocation",
        "Identifier cannot be function type",
        "Expression need to have value",
        "Math error",
    };
    #define Trace(t) if(debug_err == 1) printf("%s\n",t);
%}

%union {
    bool b_val;
    float f_val;
    int i_val;
    char* s_val;
    int type;
    expr_id id;
    symbol_type sym;
}

%start program

%type<i_val> variable_type for_start for_dec_start
%type<id> expr
%type<sym> invocation

%left OR
%left AND
%left NOT
%left '<' LE '=' GE '>' NE
%left '+' '-' 
%left '*' '/' MOD
%nonassoc UMINUS

/* tokens */
%token ARRAY BEGINS BOOL CHAR CONST DECREASING DEFAULT DO ELSE END EXIT FALSE FOR FUNCTION GET IF INT LOOP OF PUT PROCEDURE REAL RESULT RETURN SKIP STRING THEN TRUE VAR WHEN
%token LE GE NE MOD DEC OR AND NOT TD
%token <s_val> STR_CONST_VALUE
%token <i_val> INT_CONST_VALUE
%token <f_val> FLOAT_CONST_VALUE
%token <s_val> IDENT

%%
/* 
    Starting Rules
*/
program:    declaration
            {
                /* 
                    After declare start main method
                */
                main_start();
            }
            statement_list
            {
                Trace("Start Program");

                program_end();
            }
            ;

/* 
    Declaration for Variable and Function that is optional
*/
declaration: declaration_list | ;

/* 
    Declaration left recursion
*/
declaration_list:   declaration_list var_list
                    | declaration_list function_list
                    | var_list
                    | function_list
                    ;  

/* 
    Statement that is optional
*/
statement_list: statements | ;

/*
    Statement left recursion
*/
statements: statements statement
            | statement

/*
    Function and Procedure declaration
*/
function_list:  function_dec | procedure_dec;

/*
    Declaration for variables that are optional
*/
var_list_optional:   var_lists | ;

/*
    Variable declaration left recursion
*/
var_lists:  var_lists var_list
            | var_list;

/*
    Variable declaration
*/
var_list:   const_dec | variable_dec;

/*
    Statement consisting of:
    1. Blocks
    2. Simple
    3. Conditional
    4. Loop
    5. Procedure invocation
*/
statement:  blocks
            | simple
            | conditional
            | loop
            | invocation
            {
                symbol_type a = $1;
                if(a.type == PROC_TYPE) {
                    Trace("Call procedure");
                    proc_invo(a);
                }
                else yyerror("Need to be procedure type");
            }

blocks: BEGINS
        {
            create();
        }
        var_list_optional statement_list 
        END
        {
            dump();
        }

simple: IDENT DEC expr
        {
            Trace("simple: id := expr");
            /*
                Both IDENT and expr needs to be the same type.
                expr needs to be initiated first ( have a value ).

                Two cases:
                1. Array := array type expr
                    --> Only possible if both IDENT and expr is array type
                    --> Both IDENT and expr must have the same size

                2. Ident := scalar type expr
                    --> Only possible if both IDENT and expr is scalar type 
                    --> Ident cannot be const type
            */
            return_index idx = lookup($1);
            if(idx.arr_index == -1) yyerror(err_msg[VAR_NOT_FOUND]);
            else {
                symbol_type sym = get_variable(idx);
                id_type id = $3.val;
                
                if(sym.type == ARRAY_TYPE) {
                    if(id.type != ARRAY_TYPE) yyerror(err_msg[MUST_BE_ARR]);
                    else {
                        return_index arr_idx = lookup(id.str_val);

                        id_array arr = get_variable(arr_idx).symbol_array;

                        bool err = false;

                        if(sym.symbol_array.type != arr.type) {
                            yyerror(err_msg[SAME_TYPE]); 
                            err = true;
                        }

                        if(sym.symbol_array.max_size != arr.max_size) {
                            yyerror(err_msg[SAME_SIZE]); 
                            err = true;
                        }

                        if(!err) {
                            Trace("Assignment success");
                            assign_array(idx, arr);
                        }
                    }
                }
                else if(sym.type != FUNCTION_TYPE && sym.type != PROC_TYPE) {
                    bool err = false;
                    if(!is_scalar(id)) {yyerror(err_msg[MUST_BE_SCALAR]); err = true;}
                    else {
                        if(id.init == false) {yyerror(err_msg[VAR_INIT]); err = true;}
                        if(sym.is_const_type) {yyerror(err_msg[NO_CONST]); err = true;}
                        if(sym.type != id.type) {yyerror(err_msg[SAME_TYPE]); err = true;}
                    }

                    if(!err) {
                        Trace("Assignment success");
                        assign_item(idx, id);
                        if(on_top() && $3.is_const == true) get_const_int($3.val.int_val);
                        if(sym.type == INT_TYPE) {
                            if(sym.index == -1) assign_global_var(sym.ident);
                            else assign_local_var(sym.index);
                        } 
                            
                    }
                }
                else yyerror(err_msg[NO_FUNC_TYPE]);
            }
        }
        /*
            Check if IDENT [expr] is error or not. 
            Same rule as the above Ident := scalar type
        */
        | IDENT '[' expr ']' DEC expr
        {
            Trace("simple: arr[idx] := expr");

            return_index idx = lookup($1);

            if(idx.arr_index == -1) yyerror(err_msg[VAR_NOT_FOUND]);
            else {
                symbol_type sym = get_variable(idx);

                if(sym.type != ARRAY_TYPE) yyerror(err_msg[MUST_BE_ARR]);
                else {
                    expr_id arr_idx = $3;

                    if(arr_idx.val.type != INT_TYPE) yyerror(err_msg[ID_INT]);
                    else {
                        if(arr_idx.val.int_val >= sym.symbol_array.max_size) 
                            yyerror(err_msg[ID_NOT_FOUND]);
                        else {
                            expr_id id = $6;

                            bool err = false;

                            if(!is_scalar(id.val)) {
                                yyerror(err_msg[MUST_BE_SCALAR]); 
                                err = true;
                            }

                            if(id.val.init == false) {
                                yyerror(err_msg[VAR_INIT]); 
                                err = true;
                            }
                            
                            if(!err) {
                                Trace("Assignment success");
                                assign_array_item(idx, arr_idx.val.int_val, id.val);
                            } 
                        }
                    }
                }    
            }
            

        }
        | 
        {
            put_start();
        }
        print
        | GET IDENT
        {
            Trace("simple: get");
        }
        /*
            Result may only exist in FUNCTION_TYPE variables
        */
        | RESULT expr
        {
            Trace("simple: result");

            if(func_ident_success()) {
                id_type id = $2.val;
                
                int res = in_func(id);

                if(res == SUCCESS) {
                    Trace("Result expression successful");
                    function_return();
                }
                else {
                    insert_function_err();
                    yyerror(err_msg[res]);
                }
            }
        }
        /*
            Result may only exist in PROC_TYPE variables
        */
        | RETURN
        {
            Trace("simple: return");

            if(in_proc() == SUCCESS) {
                Trace("Return expression successful");
                proc_return();
            }
            else {
                insert_function_err();
                yyerror(err_msg[MUST_BE_PROC]);
            }
        }
        | EXIT
        {
            Trace("simple: exit");
        }
        | EXIT WHEN expr
        {
            Trace("simple: exit if");
            id_type id = $3.val;
            if(id.type != BOOL_TYPE) yyerror(err_msg[MUST_BE_BOOL]);
            else loop_cond();
        }
        | SKIP
        {
            Trace("simple: skip");
            skip();
        }

print:  PUT expr
        {
            Trace("simple: put");
            expr_id temp_expr = $2;
            if(on_top() && temp_expr.is_const == true) {
                if(temp_expr.val.type == STRING_TYPE) get_const_str(temp_expr.val.str_val);
                else if(temp_expr.val.type == INT_TYPE) get_const_int(temp_expr.val.int_val);
            }

            if(temp_expr.val.type == STRING_TYPE) put_str();
            else put_int();
        }

conditional:    if_then
                END IF
                {
                    dump();
                    if_end();
                }
                | if_then
                ELSE
                {
                    Trace("ELSE");
                    dump();
                    create();
                    else_start();
                }
                var_list_optional statement_list
                END IF
                {   
                    dump();
                    else_end();
                }

if_then:    IF expr THEN
            {
                Trace("IF");
                id_type a = $2.val;
                if(a.type != BOOL_TYPE) yyerror(err_msg[MUST_BE_BOOL]);

                create();
                if_start();
            }
            var_list_optional statement_list          
            
loop:   LOOP
        {
            Trace("Loop");
            create();
            loop_start();
        }
        var_list_optional statement_list
        END LOOP
        {
            dump();
            loop_end();
        }
        /*
            For loop expr must be const expr
        */
        | for_start TD expr
        {
            Trace("For");
            int a = $1;
            expr_id b = $3;

            if(a != -10000) {
                if(b.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                else {
                    if(b.val.type != INT_TYPE) yyerror(err_msg[MUST_BE_INT]);
                    else if(a > b.val.int_val) yyerror("Starting number must be smaller than end number");
                }
                get_cond('>');
                loop_cond();
            }
        }
        var_list_optional statement_list
        END FOR
        {
            loop_plus(get_latest().index);
            dump();
            loop_end();
        }
        | for_dec_start TD expr
        {
            Trace("For");
            int a = $1;
            expr_id b = $3;

            if(a != -10000) {
                if(b.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                else {
                    if(b.val.type != INT_TYPE) yyerror(err_msg[MUST_BE_INT]);
                    else if(a < b.val.int_val) yyerror("Starting number must be greater than end number");
                }
                get_cond('<');
                loop_cond();
            }
        }
        var_list_optional statement_list
        END FOR
        {
            loop_minus(get_latest().index);
            dump();
            loop_end();
        }

for_start:  FOR IDENT ':' expr
            {
                expr_id a = $4;
                id_type temp = {
                    .type = INT_TYPE,
                    .int_val = -10000,
                    .init = false
                };
                create();

                if(a.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                else {
                    if(a.val.type != INT_TYPE) yyerror(err_msg[MUST_BE_INT]);
                    else {
                        temp.int_val = a.val.int_val;
                        temp.init = true;
                        insert($2, temp, false);
                        assign_local_var(get_variable(lookup($2)).index);
                        loop_start();
                        get_local_var(get_variable(lookup($2)).index);
                    }
                }
                
                $$ = temp.int_val;
            }

for_dec_start:   FOR DECREASING IDENT ':' expr 
                {
                    expr_id a = $5;
                    id_type temp = {
                        .type = INT_TYPE,
                        .int_val = -10000,
                        .init = false
                    };
                    create();

                    if(a.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                    else {
                        if(a.val.type != INT_TYPE) yyerror(err_msg[MUST_BE_INT]);
                        else {
                            temp.int_val = a.val.int_val;
                            temp.init = true;
                            insert($3, temp, false);
                            assign_local_var(get_variable(lookup($3)).index);
                            loop_start();
                            get_local_var(get_variable(lookup($3)).index);
                        }
                    }
                    
                    $$ = temp.int_val;
                }
/* 
    Const Variable Declaration 
    - expr only can be const_expr
    - IDENT and expr must be the same type
*/
const_dec:  CONST IDENT ':' variable_type DEC expr
            {
                Trace("Const with Type and Init");

                expr_id temp_expr = $6;

                int err = 0;
                if(temp_expr.is_const == false) { yyerror(err_msg[MUST_BE_CONST]); err = 1;}
                if($4 != temp_expr.val.type) { yyerror(err_msg[SAME_TYPE]); err = 1;}

                if(err == 0) {
                    int res = insert($2, temp_expr.val, true);

                    if(res == VAR_DECLARED) yyerror(err_msg[res]) ;
                    else Trace("Success Insertion");
                }
            }
            | CONST IDENT DEC expr
            {
                Trace("Const Variables with Init Only");

                expr_id temp_expr = $4;

                if(temp_expr.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                else {
                    int res = insert($2, temp_expr.val, true);

                    if(res == VAR_DECLARED) yyerror(err_msg[res]) ;
                    else Trace("Success Insertion Init Only");
                }
            }
            ;

/* 
    Non-Const Variable and Array Declaration
    - expr only can be const_expr
    - IDENT and expr must be the same type
    - May be declared without expr
*/
variable_dec:   VAR IDENT ':' variable_type
                {
                    Trace("Variables with Type Only");
                    
                    id_type temp_id = {
                        .type = $4,
                        .init = false,
                    };
                    
                    int res = insert($2, temp_id, false);

                    if(res == VAR_DECLARED) yyerror(err_msg[res]);
                    else {
                        Trace("Success Insertion Type Only");
                        int curr_stack = get_stack_idx($2);
                        if(curr_stack == -1) global_var_no_init($2);
                    }
                }
                | VAR IDENT DEC expr
                {
                    Trace("Variables with Init Only");

                    expr_id temp_expr = $4;

                    if(temp_expr.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                    else {
                        int res = insert($2, temp_expr.val, false);

                        if(res == VAR_DECLARED) yyerror(err_msg[res]) ;
                        else {
                            Trace("Success Insertion Init Only");
                            int curr_stack = get_stack_idx($2);
                            if(curr_stack == -1) global_var_init($2, temp_expr.val.int_val);
                            else assign_local_var(curr_stack);
                        }
                    }
                }
                | VAR IDENT ':' variable_type DEC expr
                {
                    Trace("Variables with Type and Init");

                    expr_id temp_expr = $6;

                    int err = 0;
                    if(temp_expr.is_const == false) { yyerror(err_msg[MUST_BE_CONST]); err = 1;}
                    if($4 != temp_expr.val.type) { yyerror(err_msg[SAME_TYPE]); err = 1;}

                    if(err == 0) {
                        int res = insert($2, temp_expr.val, false);

                        if(res == VAR_DECLARED) yyerror(err_msg[res]) ;
                        else {
                            Trace("Success Insertion Init Only");
                            int curr_stack = get_stack_idx($2);
                            if(curr_stack == -1) global_var_init($2, temp_expr.val.int_val);
                            else assign_local_var(curr_stack);
                        }
                    }
                }
                | VAR IDENT ':' ARRAY expr TD expr OF variable_type
                {
                    Trace("Declare array");
                    /*
                        The first expr must be bigger than the second expr in value
                    */
                    expr_id expr_a = $5;
                    expr_id expr_b = $7;

                    int err = 0;
                    if(expr_a.is_const == false || expr_b.is_const == false) yyerror(err_msg[MUST_BE_CONST]);
                    else {
                        id_type id_a = expr_a.val;
                        id_type id_b = expr_b.val;
                        if(id_a.type != INT_TYPE || id_b.type != INT_TYPE) { yyerror(err_msg[MUST_BE_INT]); err = 1;}
                        else {
                            if(id_a.int_val >= id_b.int_val) { 
                                yyerror("Starting number must be smaller than Ending number"); 
                                err = 1;
                            }
                        }
                        
                        if(err == 0) {
                            int res = insert_arr($2, id_b.int_val - id_a.int_val + 1, $9);

                            if(res == VAR_DECLARED) yyerror(err_msg[res]);
                            else Trace("Success Insertion");
                        }
                    }
                }
                ;

/* 
    Function Declaration 
*/
function_dec:   FUNCTION IDENT 
                {
                    Trace("Init function");

                    id_type temp_id = {
                        .type = FUNCTION_TYPE,
                        .init = true
                    };

                    int res = insert($2, temp_id, false);

                    /*
                        If the variable name is already declared, then yyerror
                    */
                    if(res == VAR_DECLARED) yyerror(err_msg[res]);
                    else {
                        Trace("Success Function Insertion");
                    }
                    
                    create();
                }
                '(' formal_argss ')' ':' function_return
                {
                    Trace("Define params and function return type");
                    function_start(get_function());
                }
                var_list_optional statement_list
                {
                    Trace("Inside function");
                }
                END IDENT
                {
                    Trace("End function");
                    
                    dump();
                    function_end();
                    /*
                        If the function is declared, then:
                        - End the init function
                        - If there is an error in the function then
                          erase the function from the stack

                    */
                    if(func_ident_success()) {
                        if(end_function()) yyerror(err_msg[FUNC_MUST_RETURN]);

                        if(func_is_err()) drop_function();
                        else {Trace("Function total declaration success");}
                    }
                    else yyerror(err_msg[FUNC_NOT_DECLARED]); 
                }
                ;

/*
    Return the function result type if the function is declared
*/
function_return:    variable_type
                    {
                        if(func_ident_success()) insert_function_type($1);
                    }

/* 
    Procedure Declaration 
*/
procedure_dec:  PROCEDURE IDENT 
                {
                    Trace("Init procedure");

                    id_type temp_id = {
                        .type = PROC_TYPE,
                        .init = true
                    };

                    int res = insert($2, temp_id, false);

                    /*
                        If the variable name is already declared, then yyerror
                    */
                    if(res == VAR_DECLARED) yyerror(err_msg[res]);
                    else {
                        Trace("Success Procedure Insertion");
                    }
                    
                    create();
                }
                '(' formal_argss ')'
                {
                    Trace("Define params");
                    procedure_start(get_function());
                }
                var_list_optional statement_list
                {
                    Trace("Inside procedure");
                }
                END IDENT
                {
                    Trace("End procedure");
                    
                    dump();
                    proc_return();
                    function_end(); 
                    /*
                        If the procedure is declared, then:
                        - End the init procedure
                        - If there is an error in the procedure then
                          erase the procedure from the stack

                    */
                    if(func_ident_success()){
                        end_procedure();
                        if(func_is_err()) drop_function();
                        Trace("Procedure total declaration success");
                    }
                    else yyerror(err_msg[FUNC_NOT_DECLARED]);
                }

/*
    Parameter for function/procedure declaration
*/         
formal_argss:   formal_args | ;

formal_args:    formal_args ',' arg
                | arg
                ;

arg:    IDENT ':' variable_type
        {
            /*
                If the function is declared, then insert the params to the variable
                No two parameter can have the same name 
            */
            if(func_ident_success()) {
                id_type temp_id = {
                    .type = $3,
                    .init = false
                };
                if(insert($1, temp_id, false) == SUCCESS) { 
                    insert_params($3);
                }
                else {
                    yyerror(err_msg[VAR_DECLARED]);
                    insert_function_err();
                }
            }
        }
        ;

/*
    Return variable type
*/
variable_type:  BOOL { $$ = BOOL_TYPE; }
                | REAL { $$ = FLOAT_TYPE;}
                | INT { $$ = INT_TYPE;}
                | STRING { $$ = STRING_TYPE;} 
                ;

/*
    Function and Procedure Invocation
*/
invocation: IDENT
            {
                int idx = lookup_func($1);
                if(idx == -1) yyerror(err_msg[VAR_NOT_FOUND]);
                
                /*
                    Insert function name that needs to be searched.
                    Check if the variable is a function/parameter type.
                */
                else {
                    insert_param_ident($1);
                    if(!check_function_type()) yyerror(err_msg[MUST_BE_FUNC]);
                }
            }
            '(' parameters ')'
            {
                /*
                    Return the value if it is function type
                    Return empty if function name is empty
                */
                symbol_type ret = get_return();
                restart_param();
                if(ret.return_type == 200) yyerror(err_msg[PARAM_SIZE]);
                $$ = ret;
            }
            ;

/*
    Parameter for function/procedure invocation
*/   
parameters: parameter | ;

parameter:  parameter ',' param
            | param
            ;

param:  expr
        {
            expr_id id = $1;
            int res = check_param_type(id.val);
            if(res != SUCCESS) yyerror(err_msg[res]);
           
        }

expr:   invocation
        {
            symbol_type a = $1;
            
            /* 
                If the received type is FUNCTION_TYPE, then return the result type
                If the received type is NULL, then do nothing
            */
            if(a.type == FUNCTION_TYPE) {
                Trace("Call function");

                expr_id temp;
                temp.is_const = false;
                
                id_type id = {
                    .type = a.return_type,
                    .init = true,
                    .bool_val = false,
                    .float_val = 0,
                    .int_val = 0,
                    .str_val = ""
                };

                function_invo(a);
                temp.val = id;
                $$ = temp;
            }
            else yyerror("Need to be function");
        }
        | FLOAT_CONST_VALUE
        {
            Trace("Float const");

            expr_id temp;
            temp.val = var_type(FLOAT_TYPE, false, $1, 0, "");
            temp.is_const = true;

            $$ = temp;
        }
        | INT_CONST_VALUE
        {
            Trace("Int const");

            expr_id temp;
            temp.val = var_type(INT_TYPE, false, 0, $1, "");
            temp.is_const = true;
            if(!on_top()) get_const_int(temp.val.int_val);

            $$ = temp;
        }
        | STR_CONST_VALUE
        {
            Trace("Str const");

            expr_id temp;
            temp.val = var_type(STRING_TYPE, false, 0, 0, $1);
            temp.is_const = true;
            if(!on_top()) get_const_str(temp.val.str_val);
            $$ = temp;
        }
        | '-' expr %prec UMINUS
        {
            Trace("- expr");

            expr_id id = $2;
            if(is_num(id.val)) {
                expr_id temp;
                temp.is_const = id.is_const;

                if(id.val.type == INT_TYPE) 
                    temp.val = var_type(INT_TYPE, false, 0, -id.val.int_val, "");
                else
                    temp.val = var_type(FLOAT_TYPE, false, -id.val.float_val, 0, "");

                get_op('n');
                $$ = temp;
            }
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '+' expr
        {
            Trace("+");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;
                bool float_res = false;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else {
                    aval = a.val.float_val;
                    float_res = true;
                }

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else {
                    bval = b.val.float_val;
                    float_res = true;
                }

                if(float_res) temp.val = var_type(FLOAT_TYPE, false, aval + bval, 0, "");
                else temp.val = var_type(INT_TYPE, false, 0, aval + bval, "");

                get_op('+');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '-' expr
        {
            Trace("-");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;
                bool float_res = false;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else {
                    aval = a.val.float_val;
                    float_res = true;
                }

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else {
                    bval = b.val.float_val;
                    float_res = true;
                }

                if(float_res) temp.val = var_type(FLOAT_TYPE, false, aval - bval, 0, "");
                else temp.val = var_type(INT_TYPE, false, 0, aval - bval, "");
                
                get_op('-');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '*' expr
        {
            Trace("*");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;
                bool float_res = false;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else {
                    aval = a.val.float_val;
                    float_res = true;
                }

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else {
                    bval = b.val.float_val;
                    float_res = true;
                }

                if(float_res) temp.val = var_type(FLOAT_TYPE, false, aval * bval, 0, "");
                else temp.val = var_type(INT_TYPE, false, 0, aval * bval, "");
                
                get_op('*');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '/' expr
        {
            Trace("/");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;
                bool float_res = false;
                bool err = false;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else {
                    aval = a.val.float_val;
                    float_res = true;
                }

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else {
                    bval = b.val.float_val;
                    float_res = true;
                }

                if(bval == 0) err = true;

                if(!err) {
                    if(float_res) temp.val = var_type(FLOAT_TYPE, false, aval / bval, 0, "");
                    else temp.val = var_type(INT_TYPE, false, 0, aval / bval, "");

                    get_op('/');
                    $$ = temp;
                }
                else yyerror("Denominator must not be 0");
                
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr MOD expr
        {
            Trace("mod");

            expr_id a = $1;
            expr_id b = $3;

            if(a.val.type == INT_TYPE && b.val.type == INT_TYPE) {
                expr_id temp;
                temp.is_const = false;
                temp.val = var_type(INT_TYPE, false, 0, a.val.int_val % b.val.int_val, "");

                get_op('m');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_INT]);
        }
        | IDENT '[' expr ']'
        {
            Trace("Variable array");
            return_index idx = lookup($1);

            if(idx.arr_index == -1) yyerror(err_msg[VAR_NOT_FOUND]);
            else {
                symbol_type sym = get_variable(idx);

                if(sym.type != ARRAY_TYPE) yyerror(err_msg[MUST_BE_ARR]);
                else {
                    expr_id arr_idx = $3;

                    if(arr_idx.val.type != INT_TYPE) yyerror(err_msg[ID_INT]);
                    else {
                        if(arr_idx.val.int_val >= sym.symbol_array.max_size) 
                            yyerror(err_msg[ID_NOT_FOUND]);
                        else {
                            Trace("Item of array successful get");

                            expr_id temp;
                            temp.val = get_item_from_array(idx, arr_idx.val.int_val);
                            temp.is_const = false;
                            $$ = temp;
                        }
                    }
                }    
            }
        }
        | IDENT
        {
            Trace("variable");
            return_index idx = lookup($1);

            if(idx.arr_index == -1) yyerror(err_msg[VAR_NOT_FOUND]);
            else {
                symbol_type sym = get_variable(idx);

                if(sym.type == FUNCTION_TYPE || sym.type == PROC_TYPE) {
                    yyerror(err_msg[NO_FUNC]);
                }
                    
                else {
                    Trace("Item successful get");

                    expr_id temp;

                    temp.val = get_item(idx);

                    if(sym.is_const_type == true) {
                        temp.is_const = true;
                        if(!on_top()) {
                            if(temp.val.type == STRING_TYPE) {
                                printf("ss: %s", temp.val.str_val);
                                get_const_str(temp.val.str_val);
                            }
                            else if(temp.val.type == INT_TYPE) get_const_int(temp.val.int_val);
                            else if(temp.val.type == BOOL_TYPE) {
                                if(temp.val.bool_val == true) get_const_int(1);
                                else get_const_int(0);
                            } 
                        }
                    }
                    else {
                        temp.is_const = false;

                        if(sym.index == -1) get_global_var($1);
                        else get_local_var(sym.index);
                    }

                    $$ = temp;
                }
            }
        }
        | '(' expr ')'
        {
            $$ = $2;
        }
        | TRUE
        {
            Trace("True const");

            expr_id temp;
            temp.val = var_type(BOOL_TYPE, true, 0, 0, "");
            temp.is_const = true;
            if(!on_top()) get_const_int(1);

            $$ = temp;
        }
        | FALSE
        {
            Trace("False const");

            expr_id temp;
            temp.val = var_type(BOOL_TYPE, false, 0, 0, "");
            temp.is_const = true;
            if(!on_top()) get_const_int(0);
            
            $$ = temp;
        }
        | expr '<' expr 
        {
            Trace("<");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval < bval, 0, 0, "");
                get_cond('<');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr LE expr
        {
            Trace("<=");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval <= bval, 0, 0, "");
                get_cond('l');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '=' expr
        {
            Trace("=");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval == bval, 0, 0, "");
                get_cond('=');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr GE expr
        {
            Trace(">=");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval >= bval, 0, 0, "");
                get_cond('g');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr '>' expr
        {
            Trace(">");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval > bval, 0, 0, "");
                get_cond('>');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr NE expr
        {
            Trace("<");

            expr_id a = $1;
            expr_id b = $3;

            if(is_num(a.val) && is_num(b.val)) {
                expr_id temp;
                temp.is_const = false;

                float aval;
                float bval;

                if(a.val.type == INT_TYPE) aval = a.val.int_val;
                else aval = a.val.float_val;

                if(b.val.type == INT_TYPE) bval = b.val.int_val;
                else bval = b.val.float_val;

                temp.val = var_type(BOOL_TYPE, aval != bval, 0, 0, "");
                get_cond('n');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_NUM]);
        }
        | expr AND expr
        {
            Trace("and");

            expr_id a = $1;
            expr_id b = $3;

            if(is_bool(a.val) && is_bool(b.val)) {
                expr_id temp;
                temp.is_const = false;
                temp.val = var_type(BOOL_TYPE, a.val.bool_val && b.val.bool_val, 0, 0, "");
                get_op('a');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_BOOL]);
        }
        | expr OR expr
        {
            Trace("or");

            expr_id a = $1;
            expr_id b = $3;

            if(is_bool(a.val) && is_bool(b.val)) {
                expr_id temp;
                temp.is_const = false;
                temp.val = var_type(BOOL_TYPE, a.val.bool_val || b.val.bool_val, 0, 0, "");
                get_op('o');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_BOOL]);
        }
        | NOT expr
        {
            Trace("not");

            expr_id a = $2;

            if(is_bool(a.val)) {
                expr_id temp;
                temp.is_const = false;
                temp.val = var_type(BOOL_TYPE, !a.val.bool_val, 0, 0, "");
                get_op('x');
                $$ = temp;
            } 
            else yyerror(err_msg[MUST_BE_BOOL]);
        }
        ;
%%

/* error message */
int yyerror(msg)
char *msg;
{
    extern int linenum;
    printf("Error line %d: %s\n",linenum,msg);
    //exit(-1);
}

extern FILE* yyin;
extern void create();

void main(int argc, char *argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }

    /* open input file */
    char* fname = argv[1];
    for(int i = 0; fname[i] != '.'; i++) {
        filename[i] = fname[i];
        filename[i+1] = '\0';
    }
    
    yyin = fopen(fname, "r"); 
    
    fptr = fopen(strcat(filename, ".jasm") ,"w");

    for(int i = 0; fname[i] != '.'; i++) {
        filename[i] = fname[i];
        filename[i+1] = '\0';
    }
    fprintf(fptr, "class %s\n{\n", filename);

    init();

    /* parsing */
    if (yyparse() == 1) 
    /* syntax error */
    yyerror("Parsing error !"); 
}