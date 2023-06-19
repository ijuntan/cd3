#include "symbols.h"

// Index for local variables
int local_index = 0;

// Check the current stack position
int current_index = 0;

// Check amount of variable inside each stack's element
int max_index[STACK_LENGTH];

// For each stack's element, there is a symbol_table to contain variables
symbol_type* symbol_table[STACK_LENGTH];

// Container for param invocation
temp_func_param func_param;

// Init function identifier indicator
bool init_func = false;

int get_stack_idx(char* var) {
    return_index idx = lookup(var);
    return get_variable(idx).index;
}

id_type var_type(int v_type, bool b, float f, int i, char* s) {
    id_type temp = {
        .type = v_type,
        .init = true
    };

    switch(v_type) {
        case BOOL_TYPE:
            temp.bool_val = b;
            break;
        case FLOAT_TYPE:
            temp.float_val = f;  
            break;
        case INT_TYPE:
            temp.int_val = i;
            break;
        case STRING_TYPE:
            temp.str_val = s;
            break;
        default:
            break;
    }

    return temp;
}

void init() {
    restart_param();
    symbol_table[current_index] = (symbol_type*) malloc(TABLE_LENGTH * sizeof(symbol_type));
    max_index[current_index] = 0;
}

void restart_param() {
    func_param.size = 0;
    func_param.ident = "";
}

void create() {
    current_index++;
    init();
}

return_index lookup(char* s) {
    return_index found_index= {
        .stack_index = -1,
        .arr_index = -1
    };
    for(int a = current_index; a > -1; a--) {
        int max = max_index[a];
        for(int i = 0; i < max; i++) {
            char* temp_id = symbol_table[a][i].ident;
            if(strcmp(temp_id, s) == 0){
                found_index.stack_index = a;
                found_index.arr_index = i;
                return found_index;
            }
        }
    }
    
    return found_index;
}

int lookup_func(char *s) {
    int max = max_index[0];
    for(int i = 0; i < max; i++) {
        char* temp_str = symbol_table[0][i].ident;
        if(strcmp(temp_str, s) == 0){
            return i;
        }
    }
    return -1;
} 

symbol_type get_variable(return_index idx) {
    return symbol_table[idx.stack_index][idx.arr_index];
}

symbol_type get_latest() {
    return symbol_table[current_index][0];
}

symbol_type get_function() {
    return symbol_table[0][max_index[0] - 1];
}

symbol_type get_return() {
    symbol_type empty = {
        .type = NULL_TYPE
    };

    if(func_param.ident == "") return empty;

    return_index temp;
    temp.stack_index = 0;
    temp.arr_index = lookup_func(func_param.ident);
    symbol_type func = get_variable(temp);

    if(func_param.size != func.symbol_function.param_amount) {
        empty.return_type = 200;
        return empty;
    }
    return func;
}

id_type get_item(return_index idx) {
    return symbol_table[idx.stack_index][idx.arr_index].symbol_item;
}

id_type get_item_from_array(return_index idx, int find_idx) {
    id_array arr = symbol_table[idx.stack_index][idx.arr_index].symbol_array;

    return arr.array[find_idx];
}

int insert(char* s, id_type v, bool c) {
    return_index res = lookup(s);
    if(res.stack_index == current_index && res.arr_index != -1) return VAR_DECLARED;

    int idx = max_index[current_index];
    symbol_table[current_index][idx].ident = s;
    symbol_table[current_index][idx].type = v.type;
    symbol_table[current_index][idx].symbol_item = v;
    symbol_table[current_index][idx].is_const_type = c;
    
    if(current_index == 0) symbol_table[current_index][idx].index = -1;
    else {
        symbol_table[current_index][idx].index = local_index;
        local_index++;
    }
    
    if(v.type == FUNCTION_TYPE || v.type == PROC_TYPE) {
        symbol_table[current_index][idx].return_type = NULL_TYPE;
        symbol_table[current_index][idx].function_err = false;
        symbol_table[current_index][idx].symbol_function.param_amount = 0;
        init_func = true;
    };

    max_index[current_index]++;
    return SUCCESS;
}

int insert_arr(char* s, int size, int type) {
    return_index res = lookup(s);
    if(res.stack_index == current_index && res.arr_index != -1) return VAR_DECLARED;

    int idx = max_index[current_index];
    symbol_table[current_index][idx].ident = s;
    symbol_table[current_index][idx].type = ARRAY_TYPE;

    id_array temp_arr;
    temp_arr.max_size = size;
    temp_arr.type = type;
    temp_arr.array = (id_type*) malloc(size * sizeof(id_type));

    for(int i = 0; i < size; i++) {
        id_type temp_id = {
            .type = type,
            .init = false
        };
        temp_arr.array[i] = temp_id;
    }

    id_type temp_id = {
        .type = ARRAY_TYPE,
        .str_val = s,
        .init = true
    };

    symbol_table[current_index][idx].symbol_array = temp_arr;
    symbol_table[current_index][idx].symbol_item = temp_id;
    symbol_table[current_index][idx].is_const_type = false;

    max_index[current_index]++;

    return SUCCESS;
}

void insert_params(int type) {
    int recentIdx = max_index[0] - 1;
    int amt = symbol_table[0][recentIdx].symbol_function.param_amount;
    symbol_table[0][recentIdx].symbol_function.param_type[amt] = type;
    symbol_table[0][recentIdx].symbol_function.param_amount++;
}

void insert_param_ident(char *s) {
    func_param.ident = s;
}

void insert_function_type(int type) {
    int recentIdx = max_index[0] - 1;
    symbol_table[0][recentIdx].return_type = type;
}

void insert_function_result() {
    int recentIdx = max_index[0] - 1;
    symbol_table[0][recentIdx].return_counter++;
}

void insert_function_err() {
    int recentIdx = max_index[0] - 1;
    symbol_table[0][recentIdx].function_err = true;
}

void assign_item(return_index idx, id_type id) {
    symbol_table[idx.stack_index][idx.arr_index].symbol_item = id;
}

void assign_array(return_index idx, id_array arr) {
    symbol_table[idx.stack_index][idx.arr_index].symbol_array = arr;
}

void assign_array_item(return_index idx, int arr_idx, id_type id) {
    symbol_table[idx.stack_index][idx.arr_index].symbol_array.array[arr_idx] = id;
}

int check_param_type(id_type id) {
    if(func_param.ident == "") return FUNC_NOT_DECLARED;
    int type = id.type;
    int idx = lookup_func(func_param.ident);
    
    if(func_param.size >= symbol_table[0][idx].symbol_function.param_amount)
        return PARAM_SIZE;
    if(type != symbol_table[0][idx].symbol_function.param_type[func_param.size]) {
        func_param.size++;
        return PARAM_TYPE;
    }
    if(id.init == false) {
        func_param.size++;
        return VAR_INIT;
    }

    func_param.size++;
    return SUCCESS;
}   

bool check_function_type() {
    int idx = lookup_func(func_param.ident);
    if(symbol_table[0][idx].type == FUNCTION_TYPE || symbol_table[0][idx].type == PROC_TYPE)
        return true;
    else {
        restart_param();
        return false;
    }
}

bool func_ident_success() {
    return init_func;
}

int in_func(id_type a) {
    int recentIdx = max_index[0] - 1;
    if(symbol_table[0][recentIdx].type != FUNCTION_TYPE) return MUST_BE_FUNC;
    if(symbol_table[0][recentIdx].return_type != a.type) return SAME_RETURN_TYPE;
    if(a.init == false) return VAR_INIT; 

    insert_function_result();
    return SUCCESS;
}

int in_proc() {
    int recentIdx = max_index[0] - 1;
    if(symbol_table[0][recentIdx].type != PROC_TYPE) return MUST_BE_PROC;
    return SUCCESS;
}

bool func_is_err() {
    int recentIdx = max_index[0] - 1;
    return symbol_table[0][recentIdx].function_err == true;
}

bool is_num(id_type a) {
    return a.type == INT_TYPE || a.type == FLOAT_TYPE;
}

bool is_bool(id_type a) {
    return a.type == BOOL_TYPE;  
}

bool is_scalar(id_type a) {
    return a.type == BOOL_TYPE || a.type == FLOAT_TYPE || a.type == INT_TYPE || a.type == STRING_TYPE;  
}

void dump() {
    free(symbol_table[current_index]);
    current_index--;
}

bool end_function() {
    init_func = false;
    int recentIdx = max_index[0] - 1;
    if(symbol_table[0][recentIdx].return_counter < 1) {
        insert_function_err();
        return true;
    }
    return false;
}

void end_procedure() {
    init_func = false;
}

void drop_function() {
    int recentIdx = max_index[0] - 1;
    symbol_type empty;
    symbol_table[0][recentIdx] = empty; 
    max_index[0]--;
}