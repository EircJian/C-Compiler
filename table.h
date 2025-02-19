#define MAX_TABLE_SIZE 5000
typedef struct symbol_entry *PTR_SYMB;

struct symbol_entry {
	char name[100];
	int scope;
	int offset;
	int id;
	int variant;
	int type;
	int is_ptr; // ex. int **a; --> is_ptr = 2;
	int ptr_to; // store X: point to -X(s0)
	int total_args;
	int total_locals;
	int mode;
	int address;
} table[MAX_TABLE_SIZE];

int table_counter = 0;
int decl_counter = 0;
