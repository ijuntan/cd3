#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#define TABLE_LENGTH 100
#define STACK_LENGTH 20

enum ErrorParam {
    SUCCESS,
    UNKNOWN,
    VAR_DECLARED,
    VAR_NOT_FOUND,
    ARR_NOT_FOUND,
    MUST_BE_CONST,
    NO_CONST,
    PARAM_INT,
    MUST_BE_NUM,
    MUST_BE_INT,
    MUST_BE_BOOL,
    MUST_BE_ARR,
    MUST_BE_FUNC,
    MUST_BE_PROC,
    MUST_BE_SCALAR,
    ID_INT,
    ID_NOT_FOUND,
    SAME_TYPE,
    SAME_SIZE,
    SAME_RETURN_TYPE,
    PARAM_SIZE,
    PARAM_TYPE,
    FUNC_MUST_RETURN,
    FUNC_NOT_DECLARED,
    NO_FUNC,
    NO_FUNC_TYPE,
    VAR_INIT,
    MATH_ERR,
};

enum VariableType {
    BOOL_TYPE,
    FLOAT_TYPE,
    INT_TYPE,
    STRING_TYPE,
    ARRAY_TYPE,
    FUNCTION_TYPE,
    PROC_TYPE,
    NULL_TYPE
};

// Check the variable's position in the stack
typedef struct {
    int stack_index;
    int arr_index;
} return_index;

// Variable == SCALAR_TYPE Struct
typedef struct {
    int type;
    bool bool_val;
    float float_val;
    int int_val;
    char* str_val;
    bool init;
} id_type;

// Only needed to check differentiate whether expr is const value or not
typedef struct {
    id_type val;
    bool is_const;
} expr_id;

// Variable == ARRAY_TYPE Struct
typedef struct {
    int max_size;
    int type;
    id_type* array;
} id_array;

// Variable == FUNCTION_TYPE Struct
typedef struct {
    // Total number of parameters the function has
    int param_amount;
    // Contains the parameter type
    int param_type[100];
} id_function;

// Main Variable Struct
typedef struct {
    // Name of Variable
    char* ident;
    // Variable Type
    int type;
    // Misc. Variables for const variables
    bool is_const_type;
    // Misc. Variables for FUNCTION_TYPE
    int return_type;
    int return_counter;
    bool function_err;
    //To count the index on sym table
    int index;

    id_type symbol_item;
    id_array symbol_array;
    id_function symbol_function;
} symbol_type;

// Temporary container to hold parameters for invocation
typedef struct {
    // Total number of parameters
    int size;
    // Name of function to be compared to
    char* ident;
} temp_func_param;

// Return current stack index
int get_stack_idx();

//Return id_type variable
id_type var_type(int v_type, bool b, float f, int i, char* s);

// Initialize program
void init();
void create();
void restart_param();

// Look for item's index
return_index lookup(char* s);
int lookup_func(char *s);

// Get variables from symbol table
symbol_type get_variable(return_index idx);
symbol_type get_latest();
symbol_type get_function();
symbol_type get_return();
id_type get_item(return_index idx);
id_type get_item_from_array(return_index idx, int find_idx);

// Insert variables to symbol table
int insert(char* s, id_type v, bool c);
int insert_arr(char* s, int size, int type);

// Insert function methods
void insert_params(int type);
void insert_param_ident(char *s);
void insert_function_type(int type);
void insert_function_result();
void insert_function_err();

//Assign methods
void assign_item(return_index idx, id_type id);
void assign_array(return_index idx, id_array arr);
void assign_array_item(return_index idx, int arr_idx, id_type id);

// Parameter checking invocation methods
int check_param_type(id_type id);

// Error checking methods
bool check_function_type();
bool func_ident_success();
int in_func(id_type a);
int in_proc();
bool func_is_err();
bool is_num(id_type a);
bool is_bool(id_type a);
bool is_scalar(id_type a);

//Free methods
void dump();
bool end_function();
void end_procedure();
void drop_function();

