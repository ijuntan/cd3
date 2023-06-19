%{
        #include<stdio.h>
        #include<stdbool.h>
        #include<ctype.h>
        #include"symbols.h"
        #include "y.tab.h"
        #define MAX_LINE_LENG 256
        #define TABLE_LENGTH 100
        #define WORD_LENGTH 20
        #define LIST strcat(buf,yytext)
        #define STR strcat(str_const,yytext)
        
        #define token(s,t) {LIST; if(debug == 1) printf("<%s>\n",s); return(t);}
        #define tokenInteger(s,i,t) {LIST; if(debug == 1) printf("<%s:%d>\n",s,i); return(t);}
        #define tokenFloat(s,f,t) {LIST; if(debug == 1) printf("<%s:%f>\n",s,f); return(t);}
        #define tokenString(s,c,t) {LIST; if(debug == 1) printf("<%s:%s>\n",s,c); return(t);}

        int linenum = 1;
        int debug = 0;
        char buf[MAX_LINE_LENG];
        char str_const[MAX_LINE_LENG];
        
%}

%s LONG_COMMENT STRING_CONST

%%
<STRING_CONST>\n        {
                                BEGIN 0;
                                str_const[0] = '\0';
                                printf("%d: Wrong input of string\n", linenum);
                                linenum++;
                                buf[0] = '\0';
                        }

        /* String Const */
<STRING_CONST>\"\"      {
                                strcat(buf,"\"");
                                strcat(str_const,"\"");
                        }

<STRING_CONST>\"        {
                                BEGIN 0;
                                yylval.s_val = strdup(str_const);
                                tokenString("string", str_const, STR_CONST_VALUE);
                        }

<STRING_CONST>[^"]*     {
                                LIST;
                                STR;
                        }

        /* Next Line */
\n      {
                LIST;
                printf("%d: %s", linenum, buf);
                linenum++;
                buf[0] = '\0';
        }
 
        /* Long comment */
<INITIAL>"{%"   {
                        BEGIN LONG_COMMENT;
                        LIST;
                }

<LONG_COMMENT>"%}"      {
                                BEGIN 0;
                                LIST;
                        }

<LONG_COMMENT>.         {
                                LIST;
                        }


        /* Start String Const */
<INITIAL>\"     {
                        BEGIN STRING_CONST;
                        str_const[0] = '\0';
                        LIST;
                }

        /* Tabs, whitespace and short comment */
<INITIAL>[ \t]* |
<INITIAL>\%.*   {
                        LIST;
                } 

        /* Keywords */
<INITIAL>array {token(yytext, ARRAY)}
<INITIAL>begin {token(yytext, BEGINS)}
<INITIAL>bool {token(yytext, BOOL)}
<INITIAL>char {token(yytext, CHAR)}
<INITIAL>const {token(yytext, CONST)}
<INITIAL>decreasing {token(yytext, DECREASING)}
<INITIAL>default {token(yytext, DEFAULT)}
<INITIAL>do {token(yytext, DO)}
<INITIAL>else {token(yytext, ELSE)}
<INITIAL>end {token(yytext, END)}
<INITIAL>exit {token(yytext, EXIT)}
<INITIAL>false {token(yytext, FALSE)}
<INITIAL>for {token(yytext, FOR)}
<INITIAL>function {token(yytext, FUNCTION)}
<INITIAL>get {token(yytext, GET)}
<INITIAL>if {token(yytext, IF)}
<INITIAL>int {token(yytext, INT)}
<INITIAL>loop {token(yytext, LOOP)}
<INITIAL>of {token(yytext, OF)}
<INITIAL>put {token(yytext, PUT)}
<INITIAL>procedure {token(yytext, PROCEDURE)}
<INITIAL>real {token(yytext, REAL)}
<INITIAL>result {token(yytext, RESULT)}
<INITIAL>return {token(yytext, RETURN)}
<INITIAL>skip {token(yytext, SKIP)}
<INITIAL>string {token(yytext, STRING)}
<INITIAL>then {token(yytext, THEN)}
<INITIAL>true {token(yytext, TRUE)}
<INITIAL>var {token(yytext, VAR)}
<INITIAL>when {token(yytext, WHEN)}
<INITIAL>mod {token(yytext, MOD)}
<INITIAL>and {token(yytext, AND)}
<INITIAL>or {token(yytext, OR)}
<INITIAL>not {token(yytext, NOT)}


        /* Integer Const */
<INITIAL>0 |
<INITIAL>[1-9][0-9]*    {
                                yylval.i_val = atoi(yytext);
                                tokenInteger("number", atoi(yytext), INT_CONST_VALUE);
                        }

        /* Float Const */
<INITIAL>0.[0-9]+ |
<INITIAL>[1-9][0-9]*.[0-9]+     {
                                        yylval.f_val = atof(yytext);
                                        tokenFloat("float", atof(yytext), FLOAT_CONST_VALUE); 
                                }

        /* Operators and Tokens*/
<INITIAL>\+ |
<INITIAL>\- |
<INITIAL>\* |
<INITIAL>\/ |
<INITIAL>\< |
<INITIAL>\> |
<INITIAL>= |
<INITIAL>\. |
<INITIAL>, |
<INITIAL>: |
<INITIAL>; |
<INITIAL>\( |
<INITIAL>\) |
<INITIAL>\[ |
<INITIAL>\] |
<INITIAL>\{ |
<INITIAL>\}     {
                        token(yytext,yytext[0]);
                }

<INITIAL>"<="   {token(yytext, LE)}
<INITIAL>">="   {token(yytext, GE)}
<INITIAL>"not=" {token(yytext, NE)}
<INITIAL>":="   {token(yytext, DEC)}
<INITIAL>".."   {token(yytext, TD)}
                
        /* Identifiers */
<INITIAL>[a-zA-Z][a-zA-Z0-9]*   {
                                        yylval.s_val = strdup(yytext);
                                        tokenString("identifier", yytext, IDENT);  
                                }

        /* Others that doesn't follow rules */
<INITIAL>.      {
                        LIST;
                        printf("%d: badchar: %s", linenum, buf);
                        linenum++;
                        buf[0] = '\0';
                }
%%
