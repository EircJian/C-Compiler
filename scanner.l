%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int lineCount = 0;
int sourceOn = 1;
int tokensOn = 1;
char lineContent[300];

int print_lex_tokens();
void print_line();


typedef enum {
	NEWLINE = 10, SPACE, TAB
}Spaces;
/*
typedef enum {
	KEY_FOR = 100, KEY_DO, KEY_WHILE, KEY_BREAK, KEY_CONTINUE, KEY_IF, KEY_ELSE, KEY_RETURN, KEY_STRUCT, KEY_SWITCH, KEY_CASE, KEY_DEFAULT, 
	KEY_VOID, KEY_INT, KEY_DOUBLE, KEY_FLOAT, KEY_CHAR, 
	KEY_CONST, KEY_SIGNED, KEY_UNSIGNED, KEY_SHORT, KEY_LONG

} Keywords;
*/
//typedef enum {
	
//} identifiers;

typedef enum {
	MACRO_NULL = 200, MACRO___COUNTER__, MACRO___LINE__, MACRO_INT_MAX, MACRO_INT_MIN, MACRO_CHAR_MAX, MACRO_CHAR_MIN, MIN, MAX
} Macros;
/*
typedef enum {
	OP_ADD = 300, OP_SUBTRACT, OP_MULTIPLY, OP_DIVIDE, OP_MOD, OP_INCREMENT, OP_DECREMENT, OP_LESS, OP_LESSEQUAL, OP_LARGER, 
	OP_LARGEREQUAL, OP_EQUAL, OP_NOTEQUAL, OP_ASSIGN, OP_AND, OP_OR, OP_NOT, OP_LOGICALAND, OP_LOGICALOR
} Operators;

typedef enum {
	PUNC_COLON = 400, PUNC_SEMICOLON, PUNC_COMMA, PUNC_PERIOD, PUNC_LEFTSQUAREBRACKET, PUNC_RIGHTSQUAREBRACKET, PUNC_LEFTBRACKET, 
	PUNC_RIGHTBRACKET, PUNC_LEFTCURLYBRACKET, PUNC_RIGHTCURLYBRACKET
} PunctuationChars;

typedef enum {
	INTEGER = 500, FLOATINGPOINT, STRING, CHARACTER, SINGLE_COMMENT, MULTIPLE_COMMENT, IDENTIFIER 
} Constants;
*/
typedef enum {
	SOURCE_ON = 600, SOURCE_OFF, TOKENS_ON, TOKENS_OFF
} Pragma;

%}

/*Definition*/

%x MULTIPLECOMMENT

SINGLECOMMENT ("//"[^\n]*)

KEYWORDS ("for"|"do"|"while"|"break"|"continue"|"if"|"else"|"return"|"struct"|"switch"|"case"|"default"|"void"|"int"|"double"|"float"|"char"|"const"|"signed"|"unsigned"|"short"|"long")

IDENTIFIERS ([_[:alpha:]][_[:alpha:]0-9]*)

PUNCTUATIONCHARS (":"|";"|","|"."|"["|"]"|"\("|"\)"|"{"|"}")

INTEGERS ([0-9][0-9]*)

CHARS ("'\\"[abefnrtv0]"'"|"'\\\\'"|"'\\\''"|"'\\\"'"|"'\\\?'"|'.'|"'\\"[[:digit:]]+"'")

STRINGS (["][^\n]+["])

FLOATINGPOINTS ([+-]*[0-9]*[.][0-9]+|[+-]*[0-9]+[.][0-9]*)

OPERATORS ("+"|"-"|"*"|"/"|"%"|"++"|"--"|"<"|"<="|">"|">="|"=="|"!="|"="|"&&"|"||"|"!"|"&"|"|"|"~"|"^")

MACROS ("NULL"|"__COUNTER__"|"__LINE__"|"INT_MAX"|"INT_MIN"|"CHAR_MAX"|"CHAR_MIN"|"MAX"|"MIN")

PRAGMA_SOURCEON ("#pragma"[ \t]+"source"[ \t]+"on"[ \t]*)

PRAGMA_SOURCEOFF ("#pragma"[ \t]+"source"[ \t]+"off"[ \t]*)

PRAGMA_TOKENSON ("#pragma"[ \t]+"token"[ \t]+"on"[ \t]*)

PRAGMA_TOKENSOFF ("#pragma"[ \t]+"token"[ \t]+"off"[ \t]*)

%%

"/*" {BEGIN MULTIPLECOMMENT; /*return MULTIPLE_COMMENT;*/}

<MULTIPLECOMMENT>"*/" {BEGIN 0; /*return MULTIPLE_COMMENT;*/}

<MULTIPLECOMMENT>[^\n] {/*return MULTIPLE_COMMENT;*/}

<MULTIPLECOMMENT>\n {lineCount++; /*return NEWLINE;*/}

\n {lineCount++; /*return NEWLINE;*/}

{SINGLECOMMENT} {/*return SINGLE_COMMENT;*/}

[ \t] {/*return SPACE;*/}

{INTEGERS} {yylval.intVal = atoi(yytext); return INTEGER;}

{FLOATINGPOINTS} {yylval.dVal = atof(yytext); return FLOATINGPOINT;}

{CHARS} {yylval.stringPointer = strdup(yytext); return CHARACTER;}

{STRINGS} {yylval.stringPointer = strdup(yytext); return STRING;}

"NULL" {yylval.intVal = KEY_NULL; return KEY_NULL;}

"for" {yylval.intVal = KEY_FOR; return KEY_FOR;}

"do" {yylval.intVal = KEY_DO; return KEY_DO;}

"while" {yylval.intVal = KEY_WHILE; return KEY_WHILE;}

"break" {yylval.intVal = KEY_BREAK; return KEY_BREAK;}

"continue" {yylval.intVal = KEY_CONTINUE; return KEY_CONTINUE;}

"if" {yylval.intVal = KEY_IF; return KEY_IF;}

"else" {yylval.intVal = KEY_ELSE; return KEY_ELSE;}

"return" {yylval.intVal = KEY_RETURN; return KEY_RETURN;}

"struct" {yylval.intVal = KEY_STRUCT; return KEY_STRUCT;}

"switch" {yylval.intVal = KEY_SWITCH; return KEY_SWITCH;}

"case" {yylval.intVal = KEY_CASE; return KEY_CASE;}

"default" {yylval.intVal = KEY_DEFAULT; return KEY_DEFAULT;}

"int" {yylval.intVal = TYPE_INT; return TYPE_INT;}

"char4" {yylval.intVal = TYPE_CHAR4; return TYPE_CHAR4;}

"char8" {yylval.intVal = TYPE_CHAR8; return TYPE_CHAR8;}

"char" {yylval.intVal = TYPE_CHAR; return TYPE_CHAR;}

"short" {yylval.intVal = TYPE_SHORT; return TYPE_SHORT;}

"long" {yylval.intVal = TYPE_LONG; return TYPE_LONG;}

"const" {yylval.intVal = TYPE_CONST; return TYPE_CONST;}

"signed" {yylval.intVal = TYPE_SIGNED; return TYPE_SIGNED;}

"unsigned" {yylval.intVal = TYPE_UNSIGNED; return TYPE_UNSIGNED;}

"float" {yylval.intVal = TYPE_FLOAT; return TYPE_FLOAT;}

"double" {yylval.intVal = TYPE_DOUBLE; return TYPE_DOUBLE;}

"void" {yylval.intVal = TYPE_VOID; return TYPE_VOID;}

"++" {yylval.intVal = OP_INCREMENT; return OP_INCREMENT;}

"--" {yylval.intVal = OP_DECREMENT; return OP_DECREMENT;}

"<=" {yylval.intVal = OP_LESSEQUAL; return OP_LESSEQUAL;}

">=" {yylval.intVal = OP_GREATEREQUAL; return OP_GREATEREQUAL;}

"==" {yylval.intVal = OP_EQUAL; return OP_EQUAL;}

"!=" {yylval.intVal = OP_NOTEQUAL; return OP_NOTEQUAL;}

"&&" {yylval.intVal = OP_LOGICALAND; return OP_LOGICALAND;}

"||" {yylval.intVal = OP_LOGICALOR; return OP_LOGICALOR;}

">>" {yylval.intVal = OP_SHIFTRIGHT; return OP_SHIFTRIGHT;}

"<<" {yylval.intVal = OP_SHIFTLEFT; return OP_SHIFTLEFT;}

{OPERATORS} {yylval.intVal = yytext[0]; return yytext[0];}

";" {yylval.intVal = ';'; return ';';}

{PUNCTUATIONCHARS} {yylval.intVal = yytext[0]; return yytext[0];}


{MACROS} {return MACRO_NULL;}

{IDENTIFIERS} {yylval.stringPointer = strdup(yytext); return IDENTIFIER;}






{PRAGMA_SOURCEON} {sourceOn = 1; /*return SOURCE_ON;*/}

{PRAGMA_SOURCEOFF} {sourceOn = 0; /*return SOURCE_OFF;*/}

{PRAGMA_TOKENSON} {tokensOn = 1; /*return TOKENS_ON;*/}

{PRAGMA_TOKENSOFF} {tokensOn = 0; /*return TOKENS_OFF;*/}

%%
// C Code Section

int print_lex_tokens() {

	memset(lineContent, 0, 300);
	int token;
	while(token = yylex()){

		strcat(lineContent, yytext);
		//printf("input: %s\n", yytext);
		if(token >= 600 && tokensOn) { // pragma
			
			//printf("TEST: token");
			//ECHO;
			//printf("\n");
		}
		else if(token >= 500 && tokensOn) { // constants, including comment and identifier
			
			if(token == 506) {
				printf("#id:");
				ECHO;
				printf("\n");
			}
			else if(token == 504 || token == 505) {

			}
			else if(token == 500) {
				
				printf("#integer:");
				ECHO;
				printf("\n");
			}
			else if(token == 501) {
				
				printf("#float:");
				ECHO;
				printf("\n");
			}
			else if(token == 502) {
				
				printf("#string:");
				ECHO;
				printf("\n");
			}
			else if(token == 503) {
				
				printf("#char:");
				ECHO;
				printf("\n");
			}
		}
		else if(token >= 400 && tokensOn) { // punctuation chars
			
			printf("#punc:");
			ECHO;
			printf("\n");
		}
		else if(token >= 300 && tokensOn) { // operators
			printf("#op:");
			ECHO;
			printf("\n");
		}
		else if(token >= 200 && tokensOn) { // macros

			printf("#macro:");
			ECHO;
			printf("\n");
		}
		else if(token >= 100 && tokensOn) { // keywords
			
			printf("#key:");
			ECHO;
			printf("\n");
		}
		
		if(token == NEWLINE) {
			
			if(sourceOn) print_line();
			memset(lineContent, 0, 300);
		}
	}
	
	//if(sourceOn) print_line();

	return 0;
}

int yywrap(){
	return 1;
}


// Keywords && Idntifiers

// Macros

// Operators && Punctuations

// Integers && Floating Points && Characters

// Strings

// Comments

// Pragma Directives

// Comprehensive Testcases


// Print current line content
void print_line(){

	printf("%d:%s", lineCount, lineContent);
}

