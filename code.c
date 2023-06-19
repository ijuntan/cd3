#include "code.h"

// Check number of labels
int label_index = 0;

// Check label stack index
int curr_label = 0;
int curr_loop_label = 0;

// If no more declaring then => get_const == true
bool still_declare = true;

// Stack for if label
int max_label[100];

// Stack for loop label
int loop_label[100];

extern int current_index;

char* tp[4] = {"bool", "real", "int", "string"};

bool on_top() {
    if(current_index == 0) {
        return still_declare;
    }
    else return false;
}

void space() {
    for(int i = 0; i < current_index; i++) {
        fprintf(fptr," ");
    }
}

void program_end() {
    fprintf(fptr, " return\n }\n}");
}

void main_start() {
    fprintf(fptr, " method public static void main(java.lang.String[])\n");
    fprintf(fptr, " max_stack 15\n");
    fprintf(fptr, " max_locals 15\n {\n");
    still_declare = false;
}

void procedure_start(symbol_type sym) {
    fprintf(fptr, " method public static void %s(", sym.ident);
    for(int i = 0; i < sym.symbol_function.param_amount; i++) {
        fprintf(fptr, "%s", tp[sym.symbol_function.param_type[i]]);
        if(i != sym.symbol_function.param_amount - 1) fprintf(fptr, ", ");
    }
    fprintf(fptr, ")\n");
    fprintf(fptr, " max_stack 15\n");
    fprintf(fptr, " max_locals 15\n {\n");
}

void proc_return() {
    space();
    fprintf(fptr, " return\n");
}

void function_start(symbol_type sym) {
    fprintf(fptr, " method public static %s %s(", tp[sym.return_type], sym.ident);
    for(int i = 0; i < sym.symbol_function.param_amount; i++) {
        fprintf(fptr, "%s", tp[sym.symbol_function.param_type[i]]);
        if(i != sym.symbol_function.param_amount - 1) fprintf(fptr, ", ");
    }
    fprintf(fptr, ")\n");
    fprintf(fptr, " max_stack 15\n");
    fprintf(fptr, " max_locals 15\n {\n");
}

void function_return() {
    space();
    fprintf(fptr, " ireturn\n");
}

void function_end() {
    fprintf(fptr, " }\n");
}

void function_invo(symbol_type sym) {
    space();
    fprintf(fptr, " invokestatic int %s.%s(", filename, sym.ident);
    for(int i = 0; i < sym.symbol_function.param_amount; i++) {
        fprintf(fptr, "%s", tp[sym.symbol_function.param_type[i]]);
        if(i != sym.symbol_function.param_amount - 1) fprintf(fptr, ", ");
    }
    fprintf(fptr, ")\n");
}

void proc_invo(symbol_type sym) {
    space();
    fprintf(fptr, " invokestatic void %s.%s(", filename, sym.ident);
    for(int i = 0; i < sym.symbol_function.param_amount; i++) {
        fprintf(fptr, "%s", tp[sym.symbol_function.param_type[i]]);
        if(i != sym.symbol_function.param_amount - 1) fprintf(fptr, ", ");
    }
    fprintf(fptr, ")\n");
}

void global_var_init(char* var, int value) {
    fprintf(fptr, " field static int %s = %d\n" ,var, value);
}

void global_var_no_init(char* var) {
    fprintf(fptr, " field static int %s\n" ,var);
}

void get_global_var(char* var) {
    space();
    fprintf(fptr, " getstatic int %s.%s\n", filename, var);
}

void assign_global_var(char* var) {
    space();
    fprintf(fptr, " putstatic int %s.%s\n", filename, var);
}

void assign_local_var(int idx) {
    space();
    fprintf(fptr, " istore %d\n" ,idx);
}

void get_local_var(int idx) {
    space();
    fprintf(fptr, " iload %d\n", idx);
}

void get_const_str(char* str) {
    space();
    fprintf(fptr, " ldc \"%s\"\n", str);
}

void get_const_int(int val) {
    space();
    fprintf(fptr, " sipush %d\n", val);
}

void put_start() {
    space();
    fprintf(fptr, " getstatic java.io.PrintStream java.lang.System.out\n");
}

void put_str() {
    space();
    fprintf(fptr, " invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
}

void put_int() {
    space();
    fprintf(fptr, " invokevirtual void java.io.PrintStream.print(int)\n");
}

void skip() {
    space();
    fprintf(fptr, " getstatic java.io.PrintStream java.lang.System.out\n");
    space();
    fprintf(fptr, " invokevirtual void java.io.PrintStream.println()\n");
}

void get_op(char s) {
    space();
    switch(s) {
        case '+':
            fprintf(fptr, " iadd\n");
            break;
        case '-':
            fprintf(fptr, " isub\n");
            break;
        case '*':
            fprintf(fptr, " imul\n");
            break;
        case '/':
            fprintf(fptr, " idiv\n");
            break;
        case 'm':
            fprintf(fptr, " irem\n");
            break;
        case 'n':
            fprintf(fptr, " ineg\n");
            break;
        case 'a':
            fprintf(fptr, " iand\n");
            break;
        case 'o':
            fprintf(fptr, " ior\n");
            break;
        case 'x':
            fprintf(fptr, " ixor\n");
            break;
        default:
            break;
    }
}

void get_cond(char s) {
    space();
    fprintf(fptr, " isub\n");
    space();
    switch (s) {
        case '<':
            fprintf(fptr, " iflt");
            break;
        case '>':
            fprintf(fptr, " ifgt");
            break;
        case '=':
            fprintf(fptr, " ifeq");
            break;
        case 'l':
            fprintf(fptr, " ifle");
            break;
        case 'g':
            fprintf(fptr, " ifge");
            break;
        case 'n':
            fprintf(fptr, " ifne");
            break;
        default:
            break;
    }
    
    int l_one = label_index;
    label_index++;
    fprintf(fptr, " L%d\n", l_one);

    space();
    fprintf(fptr, " iconst_0\n");

    int l_two = label_index;
    label_index++;
    space();
    fprintf(fptr, " goto L%d\n", l_two);

    fprintf(fptr, " nop\nL%d:\n", l_one);
    space();
    fprintf(fptr, "  iconst_1\n");

    fprintf(fptr, " nop\nL%d:\n", l_two);
}

void if_start() {
    curr_label++;
    max_label[curr_label] = label_index;
    label_index += 2;

    space();
    fprintf(fptr, " ifeq L%d\n", max_label[curr_label]);
}

void if_end() {
    fprintf(fptr, " nop\nL%d:\n", max_label[curr_label]);
    curr_label--;
}

void else_start() {
    space();
    fprintf(fptr, " goto L%d\n", max_label[curr_label] + 1);
    fprintf(fptr, " nop\nL%d:\n", max_label[curr_label]);
}

void else_end() {
    fprintf(fptr, " nop\nL%d:\n", max_label[curr_label] + 1);
    curr_label--;
}

void loop_start() {
    curr_loop_label++;
    loop_label[curr_loop_label] = label_index;
    label_index += 2;
    
    fprintf(fptr, " nop\nL%d:\n", loop_label[curr_loop_label]);
}

void loop_end() {
    space();
    fprintf(fptr, " goto L%d\n", loop_label[curr_loop_label]);
    fprintf(fptr, " nop\nL%d:\n", loop_label[curr_loop_label] + 1);
    curr_loop_label--;
}

void loop_cond() {
    space();
    fprintf(fptr, " ifne L%d\n", loop_label[curr_loop_label] + 1);
}

void loop_plus(int idx) {
    fprintf(fptr, " iload %d\n", idx);
    fprintf(fptr, " sipush 1\n");
    fprintf(fptr, " iadd\n");
    fprintf(fptr, " istore %d\n", idx);
}

void loop_minus(int idx) {
    fprintf(fptr, " iload %d\n", idx);
    fprintf(fptr, " sipush 1\n");
    fprintf(fptr, " isub\n");
    fprintf(fptr, " istore %d\n", idx);
}