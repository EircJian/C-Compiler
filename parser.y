%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "table.h"
#include "expr_type.h"

FILE *fp;

// variables required for symbol table
extern int table_counter;
extern int decl_counter;
int func_start = 0;
int cur_scope = 0;
int parameter_scope = 0;
int scope_to_set;
int in_func = 0;
int tmp_local_vars = 0;
char tmp_data_type[100];
int num_elements = 0;
int label_num = 0;

extern struct expr_data_type *exprs_list[10];
extern int exprs_idx;

char tmp_out[100000];
char *output_content;
int yylex();


char *tmp_reg[7];
int tmp_reg_state[7];

int find_empty_tmp_reg(){
	int i;
	for(int i = 0; i < 7; i++){
		if(!tmp_reg_state[i]){
			tmp_reg_state[i] = 1;
			return i;
		}
	}
	printf("No available tmp_reg!");
	return -1;
}

// codegen routines
// 1. stack operations
int push(char *reg){

	printf("\taddi sp, sp, -8\n");
	printf("\tsd %s, 0(sp)", reg);
}

int pop(){

	int reg_num = find_empty_tmp_reg();
	printf("\tld t%d, 0(sp)\n", reg_num);
        printf("\taddi sp, sp, 8\n");
	return reg_num;
}

// 2. function invocation
// 2.1 A part
void codegen_func_A(int num_args){
	
	// save callee-saved reg
	fprintf(fp, "\taddi sp, sp, -136\n");
	fprintf(fp, "\tsd sp, 96(sp)\n");
	fprintf(fp, "\tsd s0, 88(sp)\n");
	fprintf(fp, "\tsd s1, 80(sp)\n");
	fprintf(fp, "\tsd s2, 72(sp)\n");
	fprintf(fp, "\tsd s3, 64(sp)\n");
	fprintf(fp, "\tsd s4, 56(sp)\n");
	fprintf(fp, "\tsd s5, 48(sp)\n");
	fprintf(fp, "\tsd s5, 48(sp)\n");
	fprintf(fp, "\tsd s6, 40(sp)\n");
	fprintf(fp, "\tsd s7, 32(sp)\n");
	fprintf(fp, "\tsd s8, 24(sp)\n");
	fprintf(fp, "\tsd s9, 16(sp)\n");
	fprintf(fp, "\tsd s10, 8(sp)\n");
	fprintf(fp, "\tsd s11, 0(sp)\n");

	// set new frame
	fprintf(fp, "\taddi s0, sp, 136\n");
	
	fprintf(fp, "\n");	

	// set arguments
	int i;
	for(i = 0; i < num_args; i++){
		fprintf(fp, "\taddi sp, sp, -8\n");
		fprintf(fp, "\tsd a%d, 0(sp)\n", i);
	}
	fprintf(fp, "\n");
}

// 2.2 B part
void codegen_func_B(){

	// restore stack pointer(sp) to frame pointer(s0)-136
	//fprintf(fp, "\taddi sp, s0, -136\n");

        // save callee-saved reg
        fprintf(fp, "\tld sp, 96(sp)\n");
        fprintf(fp, "\tld s0, 88(sp)\n");
        fprintf(fp, "\tld s1, 80(sp)\n");
        fprintf(fp, "\tld s2, 72(sp)\n");
        fprintf(fp, "\tld s3, 64(sp)\n");
        fprintf(fp, "\tld s4, 56(sp)\n");
        fprintf(fp, "\tld s5, 48(sp)\n");
        fprintf(fp, "\tld s5, 48(sp)\n");
        fprintf(fp, "\tld s6, 40(sp)\n");
        fprintf(fp, "\tld s7, 32(sp)\n");
        fprintf(fp, "\tld s8, 24(sp)\n");
        fprintf(fp, "\tld s9, 16(sp)\n");
        fprintf(fp, "\tld s10, 8(sp)\n");
        fprintf(fp, "\tld s11, 0(sp)\n");
	
	// restore sp
	fprintf(fp, "\taddi sp, sp, 136\n");

        // store the return value in a0
        //printf("\tld a0, sp, 104\n");

        // return
	fprintf(fp, "\tjalr zero, 0(ra)\n");
	
	fprintf(fp, "\n");
}

// 2.3 C part
void codegen_func_C(int num_args, int offset, char *func_name){
	int i;
	for(i = 0; i < num_args; i++){
		int reg_num = find_empty_tmp_reg();
		printf("\tld t%d, -%d(s0)\n", reg_num, offset * 8 + 104);
		printf("\tmv a%d, t%d\n", i, reg_num);
	}
	printf("\tjal ra, %s\n", func_name);

	printf("\taddi sp, sp, -8\n");
        printf("\tsd ra, 0(sp)\n");
}

// 2.4 D part
void codegen_func_D(int offset){
	
	printf("\tsd a0, -%d(s0)\n", offset * 8 + 104);

	printf("\tld ra, 0(sp)\n");
        printf("\taddi sp, sp, 8\n");
}


// codegen of two specific functions for arduino
void digitalWrite(int pin, int value){
	fprintf(fp, "\taddi sp, sp, -8\n");
	fprintf(fp, "\tsd ra, 0(sp)\n");
	//fprintf(fp, "\tli a0, %d\n", pin);
	//fprintf(fp, "\tli a1, %d\n", value);
	fprintf(fp, "\tjal ra, digitalWrite\n");
	
	fprintf(fp, "\tld ra, 0(sp)\n");
	fprintf(fp, "\taddi sp, sp, 8\n");
	fprintf(fp, "\n");
}

void delay(int ms){
	fprintf(fp, "\taddi sp, sp, -8\n");
        fprintf(fp, "\tsd ra, 0(sp)\n");
        //fprintf(fp, "\tli a0, %d\n", ms);
        fprintf(fp, "\tjal ra, delay\n");
        
	fprintf(fp, "\tld ra, 0(sp)\n");
        fprintf(fp, "\taddi sp, sp, 8\n");
	fprintf(fp, "\n");
}




// routines for manipulation of symbol table
char *install_symbol(char *sname, int ptr_or_not){
	//printf("%d\n", table_counter);
	if(table_counter >= MAX_TABLE_SIZE) printf("No more space in symbol table!!!\n");
	else {
		table[table_counter].scope = cur_scope;
		strcpy(table[table_counter].name, sname);
		table[table_counter].is_ptr = ptr_or_not;
		
		// set offset
		if(table_counter == 0 || cur_scope == table[table_counter-1].scope + 1)
			table[table_counter].offset = 0;
		else if(cur_scope == table[table_counter-1].scope)
			table[table_counter].offset = table[table_counter-1].offset + 1;

		// set variant --> 0: var, 1: func
		//table[table_counter].variant = variant;

		// set mode --> 0: global, 1: local, 2: argument
		//table[table_counter].mode = mode;

		table_counter++;
	}
	return sname;
}

int lookup_symbol(char *sname){
	int i;
	if(table_counter == 0) return -1;
	for(i = table_counter-1; i >= 0; i--){
		if(!strcmp(table[i].name, sname))
			return i;
	}
	return -1;
}

char *delete_entries(int scope){
	int i;
	for(i = table_counter-1; i >= 0; i--){
		if(table[i].scope != scope) break;
		fprintf(fp, "\taddi sp, sp, 8\n");
                //fprintf(fp, "\n");
	}
	fprintf(fp, "\n");
	table_counter = i + 1;
}

void dump_symbol_entry_state(int idx){
	printf("table[%d]:", idx);
	printf("\n\tname: %s", table[idx].name);
	printf("\n\tscope: %d", table[idx].scope);
	printf("\n\toffset: %d", table[idx].offset);
	//printf("id: %s\n\t", table[idx].name);
	printf("\n\tvariant: %d", table[idx].variant);
	printf("\n\ttype: %d", table[idx].type);
	printf("\n\ttotal_args: %d", table[idx].total_args);
	printf("\n\ttotal_locals: %d", table[idx].total_locals);
	printf("\n\tmode: %d", table[idx].mode);
	printf("\n\taddress: -%d(s0)", table[idx].address);
	printf("\n");
}


%}
%union{
	int intVal;
	char charVal;
	char *stringPointer;
	double dVal;
	
	struct expr_data_type *expr_ptr;
}

%token<intVal> EMPTYSTRING

%token<stringPointer> TYPE_INT TYPE_LONGLONG TYPE_LONG TYPE_SHORT TYPE_CHAR TYPE_CHAR4 TYPE_CHAR8 TYPE_SIGNED TYPE_UNSIGNED TYPE_FLOAT TYPE_DOUBLE TYPE_VOID TYPE_CONST

%token<intVal> ';' '[' ']' '{' '}'

%token<intVal> KEY_FOR KEY_DO KEY_WHILE KEY_BREAK KEY_CONTINUE KEY_IF KEY_ELSE KEY_RETURN KEY_STRUCT KEY_SWITCH KEY_CASE KEY_DEFAULT KEY_NULL

/*%token<intVal> OP_INCREMENT OP_DECREMENT*/

%token<intVal> INTEGER SINGLE_COMMENT MULTIPLE_COMMENT 

%token<stringPointer> IDENTIFIER

%token<dVal> FLOATINGPOINT

%token<stringPointer> STRING

%token<stringPointer> CHARACTER

%type<stringPointer> func_defs

%type<stringPointer> decl var_decl scalar_decl array_decl func_decl func_def func_name_decl array_decl_identifier

%type<intVal> initializer

%type<stringPointer> decl_identifier /*initializer*/ array_dimension array_initializer number_list parameter_list

%type<intVal> whole_data_type parameter_whole_data_type const_or_not signed_or_not int_specifier ll_l_sh_ch signed_unsigned_float_double_void
/*
%type<stringPointer> whole_data_type const_or_not signed_or_not int_specifier ll_l_sh_ch signed_unsigned_float_double_void
*/
%type<expr_ptr> expr arithmetic_expr bitwise_expr logical_expr assign_expr increment decrement variable literal exprs

%type<expr_ptr> address_of dereference

%type<stringPointer> stmt expr_stmt if_else_stmt switch_stmt switch_clauses stmts while_stmt for_stmt expr_or_noexpr compound_stmt in_compound

%type<intVal> if_header if_else_header do_while_header





%type<expr_ptr> function_call array_access /*dereference address_of*/ type_cast

%left<stringPointer> ','

%right<stringPointer> '='

%left<stringPointer> OP_LOGICALOR

%left<stringPointer> OP_LOGICALAND

%left<stringPointer> '|'

%left<stringPointer> '^'

%left<stringPointer> '&'

%left<stringPointer> OP_EQUAL OP_NOTEQUAL

%left<stringPointer> '<' '>' OP_LESSEQUAL OP_GREATEREQUAL

%left<stringPointer> OP_SHIFTRIGHT OP_SHIFTLEFT

%left<stringPointer> '+' '-'

%left<stringPointer> '*' '/' '%'

%nonassoc UMINUS UPLUS

%right<stringPointer> ')' '!' '~' OP_INCREMENT OP_DECREMENT

%left<stringPointer> '(' OP_POSTFIXINCREMENT OP_POSTFIXDECREMENT

%start program

%%

program:
       decl { /*output_content = $1;*/ /*printf("%s", output_content);*/ }
	| decl func_defs {
		/*printf("%s", output_content);*/
		//output_content = (char *)malloc(sizeof(char) * (strlen($1) + strlen($2) + 1));
                //sprintf(output_content, "%s%s", $1, $2);
		//free($1);
		//free($2);
		//output_content = $$;
		}
	| func_defs { /*output_content = $1;*/ /*printf("%s", output_content);*/ };

func_defs:
	  func_def func_defs {
		}
	| func_def {
		};

decl:
	 var_decl {
		}
	| func_decl {
		}
	| decl var_decl {
		}
	| decl func_decl {
		};

var_decl:
	 whole_data_type  scalar_decl ';' {
			int i;
			for(i = decl_counter; i < table_counter; i++){
				table[i].type = $1;
				table[i].variant = 0;
				table[i].mode = (cur_scope == 0 ? 0 : 1);
			}
			decl_counter = table_counter;
		}
	| whole_data_type  array_decl ';' {
			int i;
			for(i = decl_counter; i < table_counter; i++){
                                table[i].type = $1;
                                if(i == decl_counter) table[i].variant = 2;
				else table[i].variant = 0;
                                table[i].mode = (cur_scope == 0 ? 0 : 1);
                        }
                        decl_counter = table_counter;
		};

scalar_decl:
	    scalar_decl ',' decl_identifier initializer {
			if($4){
				// pop the initializer value
				fprintf(fp, "\tld t1, 0(sp)\n");
                        	fprintf(fp, "\taddi sp, sp, 8\n");

				// calculate and push result
                        	fprintf(fp, "\tsd t1, -%d(s0)\n", table[table_counter-1].address);
                        	fprintf(fp, "\taddi sp, sp, -8\n");
                        	fprintf(fp, "\tsd t1, 0(sp)\n");
                        	fprintf(fp, "\n");

                        	// pop stacktop
                        	fprintf(fp, "\tld t3, 0(sp)\n");
                        	fprintf(fp, "\taddi sp, sp, 8\n");
                        	fprintf(fp, "\n");
			}
		}
	| decl_identifier initializer {
			if($2){
				// pop the initializer value
				fprintf(fp, "\tld t1, 0(sp)\n");
                        	fprintf(fp, "\taddi sp, sp, 8\n");

				// calculate and push result
                        	fprintf(fp, "\tsd t1, -%d(s0)\n", table[table_counter-1].address);
                        	fprintf(fp, "\taddi sp, sp, -8\n");
                        	fprintf(fp, "\tsd t1, 0(sp)\n");
                        	fprintf(fp, "\n");

                        	// pop stacktop
                        	fprintf(fp, "\tld t3, 0(sp)\n");
                        	fprintf(fp, "\taddi sp, sp, 8\n");
                        	fprintf(fp, "\n");
			}
		};


decl_identifier:
	  '*' IDENTIFIER {
			int lookup_idx = lookup_symbol($2);
			if(lookup_idx == -1){
				install_symbol($2, 1);
				fprintf(fp, "\tli t0, 0\n");
				fprintf(fp, "\taddi sp, sp, -8\n");
                        	fprintf(fp, "\tsd t0, 0(sp)\n");
				fprintf(fp, "\n");
				table[table_counter-1].address = 144 + table[table_counter-1].offset * 8;
				//table[table_counter-1].ptr_to = 

				tmp_local_vars += in_func; // calculating total_locals for function
			}
			else if(table[lookup_idx].variant == 1){
				decl_counter = lookup_idx;
			}
			else
				printf("Var redefinition!");
		}
	| IDENTIFIER {
			int lookup_idx = lookup_symbol($1);
			if(lookup_idx == -1){
                                install_symbol($1, 0);
				if(strcmp($1, "codegen")){
					fprintf(fp, "\tli t0, 0\n");
                                	fprintf(fp, "\taddi sp, sp, -8\n");
                                	fprintf(fp, "\tsd t0, 0(sp)\n");
                                	fprintf(fp, "\n");
					table[table_counter-1].address = 144 + table[table_counter-1].offset * 8;
				}
				tmp_local_vars += in_func; // calculating total_locals for function
			}
			else if(table[lookup_idx].variant == 1){
				decl_counter = lookup_idx;
			}
			else
                                printf("Var redefinition!");
		};

initializer:
	    '=' expr {
			$$ = 1;
			if(table[table_counter-1].is_ptr) table[table_counter-1].ptr_to = $2->int_val;
			/*
			// push $2
			if($2->table_idx != -1){
                                //printf("\tld t1, -%d(s0)\n", table[$2->table_idx].address);
                                //printf("\taddi sp, sp, -8\n");
                                //printf("\tsd t1, 0(sp)\n");
                                //printf("\n");
                        }
                        else {
                                printf("\tli t1, %d\n", $2->int_val);
                                printf("\taddi sp, sp, -8\n");
                                printf("\tsd t1, 0(sp)\n");
                                printf("\n");
                        }
			*/
                        // It's the end of the life of an expr, so free this expr_type
			free($2);
		}
	| /* empty */ {
			$$ = 0;
			/*
			printf("\tli t1, 0\n");
                        printf("\taddi sp, sp, -8\n");
                        printf("\tsd t1, 0(sp)\n");
                        printf("\n");
			*/
		};

array_decl:
	   array_decl ',' array_decl_identifier array_dimension array_initializer {
		}
	| array_decl_identifier array_dimension array_initializer {
		};

array_decl_identifier:
		      IDENTIFIER {
			int lookup_idx = lookup_symbol($1);
                        if(lookup_idx == -1){
                                install_symbol($1, 1);
				//decl_counter = table_counter-1;
                                if(strcmp($1, "codegen")){
                                        fprintf(fp, "\tli t0, 0\n");
                                        fprintf(fp, "\taddi sp, sp, -8\n");
                                        fprintf(fp, "\tsd t0, 0(sp)\n");
                                        fprintf(fp, "\n");
                                        table[table_counter-1].address = 144 + table[table_counter-1].offset * 8;
                                        table[table_counter-1].ptr_to = 144 + table[table_counter-1].offset * 8 + 8;
                                	table[table_counter-1].variant = 2;
				}
                                //tmp_local_vars += in_func; // calculating total_locals for function
                        }
		};

array_dimension:
	        '[' expr ']' array_dimension {
		}
	| '[' expr ']' {
			num_elements = $2->int_val;

			fprintf(fp, "\tld t3, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");
			char tmp_name[500];
			//tmp_name = sprintf(char_name, "", );
			int i;
			for(i = 0; i < $2->int_val; i++){
				sprintf(tmp_name, "%d%s", i, table[decl_counter].name);
				install_symbol(tmp_name, 0);
				fprintf(fp, "\tli t0, 0\n");
                                fprintf(fp, "\taddi sp, sp, -8\n");
                                fprintf(fp, "\tsd t0, 0(sp)\n");
                                fprintf(fp, "\n");
				table[table_counter-1].variant = 0;
				table[table_counter-1].address = 144 + (table[table_counter-1].offset-table[decl_counter].offset) * 8;
			}

		};

array_initializer:
		 '=' '{' number_list '}' {
		}
	| '=' '{' '}' {
		}
	| /* empty */ {
		};

number_list:
	    exprs {
		}
	| '{' number_list '}' ',' number_list {
		}
	| '{' number_list '}' {
		};

func_decl:
	  /*whole_data_type decl_identifier*/ func_name_decl '(' parameter_list ')' ';' {
			//table[decl_counter].variant = 1;
			//table[decl_counter].mode = (cur_scope == 0 ? 0 : 1);
			//table[table_counter-1].total_args = 0;
                	//table[table_counter-1].total_locals = 0;//??
                	//table[decl_counter].type = $1;
			//decl_counter = table_counter;
			if(cur_scope != table[decl_counter].scope) cur_scope = table[decl_counter].scope;
			decl_counter += 1;
			table_counter = decl_counter;
		}
	| /*whole_data_type decl_identifier*/ func_name_decl '(' ')' ';' {
			//table[decl_counter].variant = 1;
			//table[decl_counter].mode = (cur_scope == 0 ? 0 : 1);
			table[decl_counter].total_args = 0;
			//table[table_counter-1].total_locals = 0;//??
			//table[decl_counter].type = $1;
			//decl_counter = table_counter;
			if(cur_scope != table[decl_counter].scope) cur_scope = table[decl_counter].scope;
			decl_counter += 1;
                	table_counter = decl_counter;
		};

parameter_list:
	       parameter_list ',' parameter_whole_data_type decl_identifier {
			//table[table_counter-1].scope = parameter_scope;
			table[table_counter-1].type = $3;
			table[table_counter-1].mode = 2;
			table[decl_counter].total_args += 1;
		}
	| parameter_whole_data_type decl_identifier {
			//table[table_counter-1].scope = parameter_scope;
			table[table_counter-1].type = $1;
			table[table_counter-1].mode = 2;
			table[decl_counter].total_args += 1;
		};

parameter_whole_data_type:
		    whole_data_type {
			$$ = $1;
			//parameter_scope = cur_scope + 1;
			cur_scope = table[decl_counter].scope + 1;
		};

whole_data_type:
	        const_or_not signed_or_not int_specifier TYPE_INT {
		$$ = 1000 + $3 * 100 + $2 * 10 + $1;
		}
	| const_or_not signed_or_not ll_l_sh_ch {
		$$ = $3 * 100 + $2 * 10 + $1;
		}
	| const_or_not signed_unsigned_float_double_void {
		$$ = $2 * 10 + $1;
		}
	| TYPE_CONST {/*$$ = $1;*/
		$$ = 1;
		};

const_or_not:
	     TYPE_CONST { // 1
		$$ = 1;
		}
	| /* empty */ { // 0
		$$ = 0;
		};

signed_or_not:
	      TYPE_SIGNED { // 2
		$$ = 2;
		}
	| TYPE_UNSIGNED { // 1
		$$ = 1;
		}
	| /* empty */{ // 0
		$$ = 0;
		};

int_specifier:
	      TYPE_LONG TYPE_LONG { // 3
		$$ = 3;
		}
	| TYPE_LONG { // 2
		$$ = 2;
		}
	| TYPE_SHORT { // 1
		$$ = 1;
		}
	| /* empty */{ // 0
		$$ = 0;
		};

ll_l_sh_ch:
	   TYPE_LONG TYPE_LONG { // 6
		$$ = 6;
		}
	| TYPE_LONG { // 5
		$$ = 5;
		}
	| TYPE_SHORT { // 4
		$$ = 4;
		}
	| TYPE_CHAR { // 3
		$$ = 3;
		}
	| TYPE_CHAR4 { // 2
                $$ = 2;
		}
	| TYPE_CHAR8 { // 1
                $$ = 1;
		};

signed_unsigned_float_double_void:
				  TYPE_SIGNED { // 5
		$$ = 5;
		}
	| TYPE_UNSIGNED { // 4
		$$ = 4;
		}
	| TYPE_FLOAT { // 3
		$$ = 3;
		}
	| TYPE_DOUBLE { // 2
		$$ = 2;
		}
	| TYPE_VOID { // 1
		$$ = 1;
		};

func_def:
	 func_def_header func_def_compound_stmt {
			
			//int i;			
			//for(i = 0; i < table_counter; i++){
                	//	dump_symbol_entry_state(i);
        		//}
			
			// exit function body
			//fprintf(fp, "\taddi sp, sp, %d\n", tmp_local_vars * 8);
			//fprintf(fp, "\n");
			delete_entries(cur_scope--);
			in_func = 0;
			tmp_local_vars = 0;
			if(!strcmp(table[func_start].name, "codegen")){
                                codegen_func_B();
                        }
		}
	/*| func_def_header func_def_compound_stmt {
			in_func = 0;
			tmp_local_vars = 0;
		}*/;

func_name_decl:
	       whole_data_type decl_identifier {
			table[decl_counter].variant = 1;
                        table[decl_counter].mode = (cur_scope == 0 ? 0 : 1);
                        table[decl_counter].type = $1;
		};

func_def_header:
	        /*whole_data_type decl_identifier*/func_name_decl '(' parameter_list ')' {
			//table[decl_counter].variant = 1;
                        //table[decl_counter].mode = (cur_scope == 0 ? 0 : 1);
                        //table[decl_counter].type = $1;
                        func_start = decl_counter;
			decl_counter = table_counter;
			//cur_scope--;
			
			// set parameter_scope to zero
			parameter_scope = 0;

			// prepare to enter function
			//cur_scope++;
			in_func = 1;
                        tmp_local_vars = 0;
			
			fprintf(fp, ".global %s\n", table[func_start].name);
			fprintf(fp, "%s:\n", table[func_start].name);

		}
	| /*whole_data_type decl_identifier*/func_name_decl '(' ')' {
			//table[decl_counter].variant = 1;
                        //table[decl_counter].mode = (cur_scope == 0 ? 0 : 1);
                        table[decl_counter].total_args = 0;
                        //table[decl_counter].type = $1;
                        func_start = decl_counter;
			decl_counter = table_counter;

			// set parameter_scope to zero
                        parameter_scope = 0;

			// prepare to enter function
			cur_scope++;
			in_func = 1;
                        tmp_local_vars = 0;

			fprintf(fp, ".global %s\n", table[func_start].name);
                        fprintf(fp, "%s:\n", table[func_start].name);
			if(!strcmp(table[func_start].name, "codegen")){
				codegen_func_A(0);
			}
		};

func_def_compound_stmt:
		       compound_stmt {
			table[func_start].total_locals = tmp_local_vars;
			//if(!strcmp(table[func_start].name, "codegen")){
                        //        codegen_func_B();
                        //}
		};

/*
arithmetic_expr: ok!
bitwise_expr: ok!
logical_expr: ok!
variable: ok!
literal: ok!
(expr): ok!
assign_expr: ok!
function_call: ok!
address_of: ok!
dereference: ok!
increment: ok! need checking
decrement: ok! need checking
type_cast: X
KEY_NULL: ok!
*/
expr:
     arithmetic_expr {
			$$ = $1;
		}
	| bitwise_expr {
		}
	| logical_expr {
			$$ = $1;
		}
	| variable {
			$$ = $1;
		}
	| literal {
			$$ = $1;
		}
	| '(' expr ')' {
			$$ = $2;
		}
	| assign_expr {
			$$ = $1;
		}
	| function_call {
		}
	| address_of {
			$$ = $1;
		}
	| dereference {
			$$ = $1;
		}
	| increment {
		}
	| decrement {
		}
	| type_cast {
		}
	| KEY_NULL {
		};

arithmetic_expr:
	        expr '+' expr {
                        // pop $3
                        fprintf(fp, "\tld t1, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");
                        // pop $1
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");
                        // calculate and push result

			if($1->type == 200 && $3->type == 200){
				fprintf(fp, "\tli t3, 256\n");
				fprintf(fp, "\tli t6, 128\n");
				fprintf(fp, "\tli s6, -1\n");


				fprintf(fp, "\trem t4, t0, t3\n");
				fprintf(fp, "\tdiv s5, t4, t6\n");
				fprintf(fp, "\tmul s5, t3, s6\n");
				fprintf(fp, "\tadd t4, t4, s5\n");

				fprintf(fp, "\trem t5, t1, t3\n");
				fprintf(fp, "\tdiv s5, t5, t6\n");
				fprintf(fp, "\tmul s5, t3, s6\n");
				fprintf(fp, "\tadd t5, t5, s5\n");

				fprintf(fp, "\tadd s1, t4, t5\n");

				fprintf(fp, "\n");
				
				fprintf(fp, "\trem t4, t0, t3\n");
                                fprintf(fp, "\tdiv s5, t4, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t4, t4, s5\n");

                                fprintf(fp, "\trem t5, t1, t3\n");
                                fprintf(fp, "\tdiv s5, t5, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t5, t5, s5\n");

                                fprintf(fp, "\tadd s2, t4, t5\n");

				fprintf(fp, "\n");
				
				fprintf(fp, "\trem t4, t0, t3\n");
                                fprintf(fp, "\tdiv s5, t4, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t4, t4, s5\n");

                                fprintf(fp, "\trem t5, t1, t3\n");
                                fprintf(fp, "\tdiv s5, t5, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t5, t5, s5\n");

                                fprintf(fp, "\tadd s3, t4, t5\n");

                                fprintf(fp, "\n");

				fprintf(fp, "\trem t4, t0, t3\n");
                                fprintf(fp, "\tdiv s5, t4, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t4, t4, s5\n");

                                fprintf(fp, "\trem t5, t1, t3\n");
                                fprintf(fp, "\tdiv s5, t5, t6\n");
                                fprintf(fp, "\tmul s5, t3, s6\n");
                                fprintf(fp, "\tadd t5, t5, s5\n");

                                fprintf(fp, "\tadd s4, t4, t5\n");

                                fprintf(fp, "\n");

				fprintf(fp, "\tadd t0, s1, s2\n");
				fprintf(fp, "\tadd t1, s3, s4\n");
				fprintf(fp, "\tadd t0, t0, t1\n");
				
				fprintf(fp, "\taddi sp, sp, -8\n");
                        	fprintf(fp, "\tsd t0, 0(sp)\n");
			}

			else {

			//if(table[$1->table_idx].variant == 2) {
                        //        fprintf(fp, "\tsd t1, 0(t0)\n");

                        //}
                        if($1->is_ptr) {
				fprintf(fp, "\tli t2, 8\n");
				fprintf(fp, "\tmul t1, t1, t2\n");
				fprintf(fp, "\tli t2, -1\n");
				fprintf(fp, "\tmul t1, t1, t2\n");
			}
			fprintf(fp, "\tadd t0, t0, t1\n");
			fprintf(fp, "\n");

                        //printf("\tsd t0, -%d(s0)\n", table[$1->table_idx].address);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");
                        // pop stacktop
                        //printf("\tld t3, 0(sp)\n");
                        //printf("\taddi sp, sp, 8\n");
                        //printf("\n");


			}



			// process the expr_type
                        $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = $1->type;
                        if(table[$1->table_idx].is_ptr && table[$1->table_idx].variant == 2) {
                                $$->is_ptr = 1;
                                $$->table_idx = $1->table_idx + 1 + $3->int_val;
                        	$$->int_val = $1->int_val + $3->int_val * 8;
			}
                        else {
                                $$->is_ptr = 0;
                                $$->table_idx = -1;
                        	$$->int_val = $1->int_val + $3->int_val;
			}
			//$$->int_val = $1->int_val + $3->int_val;
                        //$$->table_idx = -1;
                        // free the memory allocated to expr
                        free($1);
                        free($3);
		}
	| expr '-' expr {
			// pop $3
                        fprintf(fp, "\tld t1, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");
                        
			// pop $1
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");
			
			// calculate and push result
			if($1->is_ptr) {
                                fprintf(fp, "\tli t2, 8\n");
                                fprintf(fp, "\tmul t1, t1, t2\n");
                                fprintf(fp, "\tli t2, -1\n");
                                fprintf(fp, "\tmul t1, t1, t2\n");
                        }
                        fprintf(fp, "\tsub t0, t0, t1\n");
                        fprintf(fp, "\n");

                        //printf("\tld t1, -%d(s0)\n", table[$1->table_idx].address);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");

                        // pop stacktop
                        //printf("\tld t3, 0(sp)\n");
                        //printf("\taddi sp, sp, 8\n");
                        //printf("\n");

                        // process the expr_type
                        $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = $1->type;
                        if($1->is_ptr) {
				$$->is_ptr = 1;
				$$->table_idx = $1->table_idx + 1 - $3->int_val;
				$$->int_val = $1->int_val - $3->int_val * 8;
                        }
			else {
				$$->is_ptr = 0;
                        	$$->table_idx = -1;
				$$->int_val = $1->int_val - $3->int_val;
			}
			//$$->int_val = $1->int_val - $3->int_val;
                        //$$->table_idx = -1;
                        
			// free the memory allocated to expr
                        free($1);
                        free($3);
		}
	| expr '*' expr {
			// pop $3
                        fprintf(fp, "\tld t1, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");

                        // pop $1
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");

                        // calculate and push result
                        fprintf(fp, "\tmul t0, t0, t1\n");
                        fprintf(fp, "\n");

                        //printf("\tld t1, -%d(s0)\n", table[$1->table_idx].address);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");

                        // pop stacktop
                        //printf("\tld t3, 0(sp)\n");
                        //printf("\taddi sp, sp, 8\n");
                        //printf("\n");

                        // process the expr_type
                        $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = $1->type;
                        $$->is_ptr = 0;
                        $$->int_val = $1->int_val - $3->int_val;
                        $$->table_idx = -1;

                        // free the memory allocated to expr
                        free($1);
                        free($3);
		}
	| expr '/' expr {
			// pop $3
                        fprintf(fp, "\tld t1, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");

                        // pop $1
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");

                        // calculate and push result
                        fprintf(fp, "\tdiv t0, t0, t1\n");
                        fprintf(fp, "\n");

                        //printf("\tld t1, -%d(s0)\n", table[$1->table_idx].address);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");

                        // pop stacktop
                        //printf("\tld t3, 0(sp)\n");
                        //printf("\taddi sp, sp, 8\n");
                        //printf("\n");

                        // process the expr_type
                        $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = $1->type;
                        $$->is_ptr = 0;
                        $$->int_val = $1->int_val - $3->int_val;
                        $$->table_idx = -1;

                        // free the memory allocated to expr
                        free($1);
                        free($3);
		}
	| expr '%' expr {
		}
	| '-' expr %prec UMINUS {
			fprintf(fp, "\tld t0, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");
			fprintf(fp, "\tli t1, -1\n");
			fprintf(fp, "\tmul t0, t0, t1\n");
			fprintf(fp, "\taddi sp, sp, -8\n");
			fprintf(fp, "\tsd t0, 0(sp)\n");
			fprintf(fp, "\n");
			
			$$ = $2;
			$$->int_val = -$$->int_val;
		}
	| '+' expr %prec UPLUS {
		};
	
bitwise_expr:
	     '~' expr {
		}
	| expr '&' expr {
		}
	| expr '^' expr {
		}
	| expr '|' expr {
		}
	| expr OP_SHIFTLEFT expr {
		}
	| expr OP_SHIFTRIGHT expr {
		};

logical_expr:
	     '!' expr {
		}
	| expr OP_LOGICALOR expr {
                }
	| expr OP_LOGICALAND expr {
		}
	| expr OP_EQUAL expr {
			fprintf(fp, "\tld t1, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");
			fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
			fprintf(fp, "\tsub t0, t0, t1\n");
			fprintf(fp, "\taddi sp, sp, -8\n");
			fprintf(fp, "\tsd t0, 0(sp)\n");
			fprintf(fp, "\n");
		
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 1000;
                        $$->is_ptr = 0;
                        $$->int_val = $1->int_val - $3->int_val;
                        $$->table_idx = -1;
			strcpy($$->text, "EQUAL");

			free($1);
			free($3);
			//printf("\tbne zero, t0, ELSE%d\n", label_num);
			//printf("\n");
                }
	| expr OP_NOTEQUAL expr {
		}
	| expr OP_LESSEQUAL expr {
		}
	| expr OP_GREATEREQUAL expr {
		}
	| expr '<' expr {
			fprintf(fp, "\tld t1, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\tsub t0, t1, t0\n");
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");

                        $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 1000;
                        $$->is_ptr = 0;
                        $$->int_val = $3->int_val - $1->int_val;
                        $$->table_idx = -1;
                        strcpy($$->text, "LESSTHAN");

                        free($1);
                        free($3);
		}
	| expr '>' expr{
		};

assign_expr:
	    expr '=' expr {
			
			// pop $3
			fprintf(fp, "\tld t1, 0(sp)\n");
        		fprintf(fp, "\taddi sp, sp, 8\n");
			fprintf(fp, "\n");
			
			// pop $1
			fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        fprintf(fp, "\n");

//***			// calculate and push result
			if($1->table_idx == -1) fprintf(fp, "\tsd t1, -%d(s0)\n", $1->int_val);
			else if(table[$1->table_idx].variant == 2 && table[$1->table_idx].is_ptr == 0) {
				fprintf(fp, "\tsd t1, 0(t6)\n");
				//fprintf(fp, "\tli t2, %d\n", table[$1->table_idx].address);
				//fprintf(fp, "\tli t3, 8\n");
                                //fprintf(fp, "\tmul t2, t2, t2\n");
                                //fprintf(fp, "\tli t2, -1\n");
                                //fprintf(fp, "\tmul t1, t1, t2\n");
				
			}
			else fprintf(fp, "\tsd t1, -%d(s0)\n", table[$1->table_idx].address);
			//printf("\tld t1, -%d(s0)\n", table[$1->table_idx].address);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t1, 0(sp)\n");
                        fprintf(fp, "\n");

			// pop stacktop
			//printf("\tld t3, 0(sp)\n");
                        //printf("\taddi sp, sp, 8\n");
                        //printf("\n");
			

			// process the expr_type
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = $1->type;
                        if($$->is_ptr = $1->is_ptr) {
				table[$1->table_idx].ptr_to = $3->int_val;
			}
                        $$->int_val = $3->int_val;
                        $$->table_idx = $1->table_idx; 
		

			// free the memory allocated to expr
			free($1);
			free($3);
		};

function_call:
	      expr '(' exprs ')' {
			int i;
			exprs_idx--;
			//int i, j;			
			//for(i = 0, j = 0; i < strlen($3); exprs_idx--){
				
			//}
			for(i = exprs_idx; i >= 0; i--){
				fprintf(fp, "\tld t0, 0(sp)\n");
                        	fprintf(fp, "\taddi sp, sp, 8\n");
                        	fprintf(fp, "\tmv a%d, t0\n", i);
				fprintf(fp, "\n");
			}
			
			if(!strcmp($1->text, "digitalWrite")){
				//int h_or_l = 0;
				//if(!strcmp(exprs_list[0]->text, "HIGH")) h_or_l = 1;
				//else if(!strcmp(exprs_list[0]->text, "LOW")) h_or_l = 0;
				digitalWrite(exprs_list[0]->int_val, exprs_list[1]->int_val);
			}
			else if (!strcmp($1->text, "delay")){
				delay(exprs_list[0]->int_val);
			}

			fprintf(fp, "\taddi sp, sp, -8\n");
			fprintf(fp, "\tsd a0, 0(sp)\n");
			fprintf(fp, "\n");
			exprs_idx = 0;
		}
	| expr '(' ')' {
		};

address_of:
	   '&' expr {
			int lookup_idx = lookup_symbol($2->text);
			fprintf(fp, "\tld t0, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");
			if(lookup_idx != -1){
				fprintf(fp, "\tli t1, %d\n", table[lookup_idx].address);
				fprintf(fp, "\taddi sp, sp, -8\n");
				fprintf(fp, "\tsd t1, 0(sp)\n");
				fprintf(fp, "\n");

				$2->is_ptr = 1;
				$2->int_val = table[lookup_idx].address;
				$2->table_idx = -1;
				$$ = $2;
			}
			else {
				printf("Cannot get the address of a non-variable.");
			}
		};

dereference:
	    '*' expr {
			int lookup_idx = lookup_symbol($2->text);
                        fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");
                        if(lookup_idx != -1){
				fprintf(fp, "\tld t1, -%d(s0)\n", $2->int_val);
                                fprintf(fp, "\taddi sp, sp, -8\n");
                                fprintf(fp, "\tsd t1, 0(sp)\n");
				fprintf(fp, "\n");

                                $2->is_ptr = 0;
                                $2->int_val = table[lookup_idx].ptr_to;
                                $2->table_idx = -1;
                                $$ = $2;
                        }
                        else {
                                printf("Cannot dereference a non-variable.");
                        }
		};

increment:
	  OP_INCREMENT expr {
		}
	| expr OP_INCREMENT {
		};

decrement:
	  OP_DECREMENT expr {
		}
	| expr OP_DECREMENT {
		};

type_cast:
	  '(' whole_data_type ')' expr {
		}
	| '(' whole_data_type '*' ')' expr {
		};


array_access:
	     IDENTIFIER '[' expr ']' {
			
			// pop $3
			fprintf(fp, "\tld t3, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");

			// push $1[$3]
			int lookup_idx = lookup_symbol($1);
			if(lookup_idx != -1){
				fprintf(fp, "\tli t0, %d\n", table[lookup_idx].ptr_to);
				fprintf(fp, "\tli t1, 8\n");
				fprintf(fp, "\tmul t1, t3, t1\n");
				fprintf(fp, "\tadd t1, t0, t1\n");
				fprintf(fp, "\tsub t1, s0, t1\n");
				fprintf(fp, "\tmv t6, t1\n");
				fprintf(fp, "\tld t0, 0(t1)\n");
				fprintf(fp, "\taddi sp, sp, -8\n");
				fprintf(fp, "\tsd t0, 0(sp)\n");
				fprintf(fp, "\n");
			}
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 1000;
                        $$->is_ptr = 0;
                        $$->int_val = 0;
                        $$->table_idx = lookup_idx + $3->int_val + 1;
			free($3);
		};

variable:
	 IDENTIFIER {
			if(!strcmp($1, "HIGH")){
	
				$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        	$$->type = 1000;
                        	$$->is_ptr = 0;
                        	$$->int_val = 1;
				$$->table_idx = 0;

				fprintf(fp, "\tli t0, 1\n");
                                fprintf(fp, "\taddi sp, sp, -8\n");
                                fprintf(fp, "\tsd t0, 0(sp)\n");
                                fprintf(fp, "\n");
			}
			else if(!strcmp($1, "LOW")){

                                $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                                $$->type = 1000;
                                $$->is_ptr = 0;
                                $$->int_val = 0;
				$$->table_idx = 1;
				
				fprintf(fp, "\tli t0, 0\n");
                                fprintf(fp, "\taddi sp, sp, -8\n");
                                fprintf(fp, "\tsd t0, 0(sp)\n");
                                fprintf(fp, "\n");
                        }
			else if(!strcmp($1, "digitalWrite")){

                                $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                                $$->type = 10;
                                $$->is_ptr = 0;
                                strcpy($$->text, $1);
				$$->table_idx = 2;
                        }
			else if(!strcmp($1, "delay")){

                                $$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                                $$->type = 10;
                                $$->is_ptr = 0;
                                strcpy($$->text, $1);
				$$->table_idx = 3;
                        }
			else {
				int table_idx = lookup_symbol($1);
				if(table_idx != -1){

					$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
					$$->table_idx = table_idx;
                                	$$->type = table[table_idx].type;
                                	if(($$->is_ptr = table[table_idx].is_ptr) == 1){
						$$->int_val = table[table_idx].ptr_to;
					}
                                	strcpy($$->text, $1);
					
					fprintf(fp, "\tld t0, -%d(s0)\n", table[table_idx].address);
                        		fprintf(fp, "\taddi sp, sp, -8\n");
                        		fprintf(fp, "\tsd t0, 0(sp)\n");
                        		fprintf(fp, "\n");
				}
			}
		}
	| array_access {
			$$ = $1;
		};

literal:
        INTEGER {
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
			$$->type = 0;
			$$->is_ptr = 0;
			$$->int_val = $1;
			$$->table_idx = -1;
		
			fprintf(fp, "\tli t0, %d\n", $1);
                        fprintf(fp, "\taddi sp, sp, -8\n");
                        fprintf(fp, "\tsd t0, 0(sp)\n");
                        fprintf(fp, "\n");
		}
	| FLOATINGPOINT {
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 1;
                        $$->is_ptr = 0;
                        $$->float_val = $1;
			$$->table_idx = -1;
		}
	| CHARACTER {
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 2;
                        $$->is_ptr = 0;
                        $$->char_val = $1[0];
			$$->table_idx = -1;
		}
	| STRING {
			$$ = (struct expr_data_type *)malloc(sizeof(struct expr_data_type));
                        $$->type = 3;
                        $$->is_ptr = 0;
                        strcpy($$->text, $1);
			$$->table_idx = -1;
		//sprintf(tmp_out, "<expr>%s</expr>", $1);
		//$$ = (char *)malloc(sizeof(char) * strlen(tmp_out) + 1);
		//strcpy($$, tmp_out);
		};

exprs:
      exprs ',' expr {
		exprs_list[exprs_idx++] = $3;
		
		//$$ = (struct expr_data_type *)malloc(sizeof(expr_data_type) * (strlen($1) + strlen($3) + 2));
                //sprintf($$, "%s,%s", $1, $3);
                //free($1);
                //free($3);
		}
	| expr {
		exprs_list[exprs_idx++] = $1;
		};

/*
expr_stmt: ok!
if_else_stms: ok!
switch_stmt: ok!
while_stmt: ok!
for_stmt: ok!
return: ok!
break: ok!
continue: ok!
compound_stmt: ok!
*/

stmt:
     expr_stmt {
		
		}
	| if_else_stmt {
		}
	| switch_stmt {
		}
	| while_stmt {
		}
	| for_stmt {
		}
	| KEY_RETURN expr ';' {
		}
	| KEY_RETURN ';' {
		}
	| KEY_BREAK ';' {
		}
	| KEY_CONTINUE ';' {
		}
	| compound_stmt {
		};

expr_stmt:
	  expr ';'{
			// It's the end of an expression, so we have to pop the stacktop and then free the expr
			fprintf(fp, "\tld t3, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");
			fprintf(fp, "\n");
			free($1);
			//printf("ok!");
		};

if_else_stmt:
	     if_header compound_stmt {
			fprintf(fp, "L%d: \n", $1);
			//delete_entries(cur_scope--);
		}
	| if_else_header compound_stmt {
		};

if_header:
	       KEY_IF '(' expr ')'{

			//cur_scope++;
			fprintf(fp, "\tld t0, 0(sp)\n");
			fprintf(fp, "\taddi sp, sp, 8\n");

			//int k = label_num++;
			//label_num += 2;
			if(!strcmp($3->text, "EQUAL")){
				fprintf(fp, "\tbne zero, t0, L%d\n", label_num);
                        	fprintf(fp, "\n");
			}
			$$ = label_num++;
			free($3);
			//printf("L%d: \n", k);
		};

if_else_header:
	      if_header if_else_ifcompound KEY_ELSE {
			//cur_scope++;
			fprintf(fp, "L%d: \n", $1);
		};
if_else_ifcompound:
		   compound_stmt {
			//cur_scope--;
		};


switch_stmt:
	    KEY_SWITCH '(' expr ')' '{' switch_clauses '}' {
		};

switch_clauses:
	       KEY_CASE expr ':' stmts switch_clauses {
		}
	| KEY_CASE expr ':' stmts {
		}
	| KEY_DEFAULT ':' stmts switch_clauses {
		}
	| KEY_DEFAULT ':' stmts {
		};

stmts:
      stmt stmts {
		}
	| stmt {
		};

while_stmt:
	   KEY_WHILE '(' expr ')' stmt {
		}
	| do_while_header stmt KEY_WHILE '(' expr ')' ';' {
			fprintf(fp, "\tld t0, 0(sp)\n");
                        fprintf(fp, "\taddi sp, sp, 8\n");

                        //int k = label_num++;
                        //label_num += 2;
                        if(!strcmp($5->text, "LESSTHAN")){
                                fprintf(fp, "\tblt zero, t0, L%d\n", $1);
                                fprintf(fp, "\n");
                        }

			free($5);
			//fprintf(fp, "\tjal zero, L%d\n", $1);
			//fprintf(fp, "L%d: \n", label_num);
			//label_num++;
		}

do_while_header:
	     KEY_DO {
			fprintf(fp, "L%d: \n", label_num);
			$$ = label_num++;
		};


for_stmt:
	 KEY_FOR '(' expr_or_noexpr ';' expr_or_noexpr ';' expr_or_noexpr ')' stmt {
		};

expr_or_noexpr:
	    expr {
		}
	| /* empty */{
		};


compound_stmt:
	      '{' '}' {
		}
	| '{' in_compound '}' {
		};

in_compound:
	    var_decl in_compound {
		}
	| var_decl {
		}
	| stmt in_compound {
		}
	| stmt {
		};

%%



int main(){

	fp = fopen("codegen.S", "w");

	//codegen_func_A(0);

	install_symbol("HIGH", 0);
	table[table_counter-1].variant = 0;
	table[table_counter-1].type = 1000;
	table[table_counter-1].mode = 0;
	table[table_counter-1].address = 8;

	install_symbol("LOW", 0);
	table[table_counter-1].variant = 0;
	table[table_counter-1].type = 1000;
	table[table_counter-1].mode = 0;
	table[table_counter-1].address = 16;

	install_symbol("digitalWrite", 0);
	table[table_counter-1].mode = 0;
	table[table_counter-1].type = 10;
	table[table_counter-1].mode = 0;
	table[table_counter-1].total_args = 2;
	table[table_counter-1].total_locals = 0;
	table[table_counter-1].address = 24;

	install_symbol("delay", 0);
	table[table_counter-1].variant = 1;
	table[table_counter-1].type = 10;
	table[table_counter-1].mode = 0;
	table[table_counter-1].total_args = 1;
	table[table_counter-1].total_locals = 0;
	table[table_counter-1].address = 32;

	decl_counter = table_counter;

	yyparse();
	//printf("%s", output_content);
	//int i;
	//for(i = 0; i < table_counter; i++){
	//	dump_symbol_entry_state(i);
		//printf("table[%d]: %s\n", i, table[i].name);
	//}

	//codegen_func_B();


	fclose(fp);

	return 0;
}

int yyerror(char *s) {
	fprintf(stderr, "%s\n", s);
	return 0;
}
