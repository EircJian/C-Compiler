#define EMPTYSTRING 257
#define TYPE_INT 258
#define TYPE_LONGLONG 259
#define TYPE_LONG 260
#define TYPE_SHORT 261
#define TYPE_CHAR 262
#define TYPE_CHAR4 263
#define TYPE_CHAR8 264
#define TYPE_SIGNED 265
#define TYPE_UNSIGNED 266
#define TYPE_FLOAT 267
#define TYPE_DOUBLE 268
#define TYPE_VOID 269
#define TYPE_CONST 270
#define KEY_FOR 271
#define KEY_DO 272
#define KEY_WHILE 273
#define KEY_BREAK 274
#define KEY_CONTINUE 275
#define KEY_IF 276
#define KEY_ELSE 277
#define KEY_RETURN 278
#define KEY_STRUCT 279
#define KEY_SWITCH 280
#define KEY_CASE 281
#define KEY_DEFAULT 282
#define KEY_NULL 283
#define INTEGER 284
#define SINGLE_COMMENT 285
#define MULTIPLE_COMMENT 286
#define IDENTIFIER 287
#define FLOATINGPOINT 288
#define STRING 289
#define CHARACTER 290
#define OP_LOGICALOR 291
#define OP_LOGICALAND 292
#define OP_EQUAL 293
#define OP_NOTEQUAL 294
#define OP_LESSEQUAL 295
#define OP_GREATEREQUAL 296
#define OP_SHIFTRIGHT 297
#define OP_SHIFTLEFT 298
#define UMINUS 299
#define UPLUS 300
#define OP_INCREMENT 301
#define OP_DECREMENT 302
#define OP_POSTFIXINCREMENT 303
#define OP_POSTFIXDECREMENT 304
#ifdef YYSTYPE
#undef  YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
#endif
#ifndef YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
typedef union{
	int intVal;
	char charVal;
	char *stringPointer;
	double dVal;
	
	struct expr_data_type *expr_ptr;
} YYSTYPE;
#endif /* !YYSTYPE_IS_DECLARED */
extern YYSTYPE yylval;
