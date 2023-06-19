#include "symbols.h"
extern FILE* fptr;
extern char filename[100];
extern int current_index;

// Start program and statement
void program_end();
void main_start();

// Variable methods
void global_var_no_init(char* var);
void global_var_init(char* var, int value);
void get_global_var(char* var);
void get_local_var(int idx);
void get_const_str(char* str);
void get_const_int(int val);
void assign_global_var(char* var);
void assign_local_var(int idx);

// Function methods
void function_start(symbol_type sym);
void function_return();
void procedure_start(symbol_type sym);
void proc_return();
void function_end();
void function_invo(symbol_type sym);
void proc_invo(symbol_type sym);

// If methods
void if_start();
void if_end();
void else_start();
void else_end();

// Loop methods
void loop_start();
void loop_end();
void loop_cond();
void loop_plus(int idx);
void loop_minus(int idx);

// Put Methods
void put_start();
void put_str();
void put_int();

// Operator Methods
void get_op(char s);
void get_cond(char s);

// Misc.
void skip();
void space();
bool on_top();