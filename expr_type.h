typedef struct expr_data_type {

        int type;
        int is_ptr;
	int table_idx;

        char text[100];
        int int_val;
        double float_val;
        char char_val;

} *expr_type;

struct expr_data_type *exprs_list[10];
int exprs_idx = 0;
