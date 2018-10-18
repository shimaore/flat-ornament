/* Parses flat-ornament text syntax */
/* Use with [jison debugger](https://nolanlawson.github.io/jison-debugger/) */

%lex

FLOAT       [0-9]+"."(?:[0-9]+)?\b
INTEGER     [0-9]+
STRING1     [']([^'\r\n]*)[']
STRING2     ["]([^"\r\n]*)["]
PATTERN     [/](\d|\?|\.|\.\.|\.\.\.|…)+[/]
NAME        [A-Za-z_]+

%token OP NAME

%options flex

%%


/* INITIAL */

"if"            return 'IF'
"unless"        return 'UNLESS'
"then"          return 'THEN'
"else"          return 'ELSE'
"and"           return 'AND'
"or"            return 'OR'
"not"           return 'NOT'
"it"            return 'IT'
"is"            return 'IS'
"isn't"         return 'ISNT'
"isnt"          return 'ISNT'
"=="            return 'EQ'
"!="            return 'NE'
"<>"            return 'NE'
"≠"             return 'NE'
"<="            return 'GE'
">="            return 'LE'
"true"          return 'TRUE'
"false"         return 'FALSE'
"greater"       return 'GREATER'
"less"          return 'LESS'
"smaller"       return 'LESS'
"than"          return 'THAN'
"the"           return 'THE'
"of"            return 'OF'
"postpone"      return 'POSTPONE'
"→"             return 'POSTPONE'
"->"            return 'POSTPONE'
"="             return 'ASSIGN'
":"             return 'ASSIGN'
"←"             return 'ASSIGN'
"~"             return 'MATCHES'
"matches"       return 'MATCHES'

{FLOAT}         return 'FLOAT'
{INTEGER}       return 'INTEGER'
{STRING1}       return 'STRING'
{STRING2}       return 'STRING'
{PATTERN}       return 'PATTERN'
{NAME}          return (yy.op && yytext in yy.op) ? 'OP' : 'NAME'


"#"[^\r\n]*     /* end-of-line comment */
[\r\n][ ]*(?=[\r\n])      return 'NL' /* empty line */

[\r\n][ ]*(?="else")      %{
    if(!yy.indent) yy.indent = [0]
    var new_indent = yytext.length-1
    var top_indent = yy.indent[0]
    console.log("ELSE top indent = "+top_indent+", new_indent = "+new_indent)
    if (new_indent  >  top_indent) { yy.indent.unshift(new_indent); return 'INDENT' }
    if (new_indent  <  top_indent) { yy.indent.shift(); this.unput(yytext); return 'OUTDENT' }
  %}

[\r\n][ ]*(?![\r\n]|"else")      %{
    if(!yy.indent) yy.indent = [0]
    var new_indent = yytext.length-1
    var top_indent = yy.indent[0]
    console.log("NL top indent = "+top_indent+", new_indent = "+new_indent)
    if (new_indent === top_indent) { return 'NL' }
    if (new_indent  >  top_indent) { yy.indent.unshift(new_indent); return 'INDENT' }
    if (new_indent  <  top_indent) { yy.indent.shift(); this.unput(yytext); return 'OUTDENT' }
  %}

[ ]+            /* skip */
<<EOF>>         return 'EOF'
.               return yytext

/lex

%start start

%{

%}

/* operator association and precedence, if any */

%left ','
%right POSTPONE
%right ASSIGN
%right IF UNLESS cond
%left THEN ELSE then else
%left OR
%left AND
%left IS ISNT MATCHES EQ NE
%left '<' '>' GE LE
/* bitwise */
%left '+' '-'
%left '*' '/' '%'
%right NOT UMINUS
%left OF '[' '.'

%% /* grammar */

start
  : expressions EOF -> $1
  ;

expressions
  : assignment nlc expressions -> [$1,$3]
  | expression nlc expressions -> [$1,$3]
  | expression nlc -> $1
  | expression -> $1
  ;

nl
  : NL
  | nl NL
  ;

nlc
  : NL
  | ','
  | nlc NL
  ;

expressions-block
  : INDENT expressions OUTDENT -> $2
  ;

assignment
  : name ASSIGN expression  -> ['=',$1,$3]
  ;

block
  : INDENT block-lines OUTDENT -> $2
  ;

block-lines
  : expression nl block-lines -> [$1,$3]
  | expression nl -> $1
  | expression -> $1
  ;

expression
  : name                          -> $1
  | float                         -> $1
  | integer                       -> $1
  | string                        -> $1
  | TRUE                          -> true
  | FALSE                         -> false
  | IT                            -> 'it'
  | POSTPONE expression           -> $2
  | POSTPONE expressions-block    -> $2
  | expression AND expression     -> ['and',$1,$3]
  | expression OR  expression     -> ['or',$1,$3]
  | NOT expression                -> ['not',$2]
  | expression '+' expression     -> ['+',$1,$3]
  | expression '-' expression     -> ['-',$1,$3]
  | expression '*' expression     -> ['*',$1,$3]
  | expression '/' expression     -> ['/',$1,$3]
  | expression '%' expression     -> ['%',$1,$3]
  | expression '>' expression                 -> ['>',$1,$3]
  | expression GE expression                  -> ['>=',$1,$3]
  | expression IS GREATER THAN expression     -> ['>',$1,$5]
  | expression IS NOT GREATER THAN expression -> ['<=',$1,$6]
  | expression '<' expression                 -> ['<',$1,$3]
  | expression LE expression                  -> ['<=',$1,$3]
  | expression IS LESS THAN expression     -> ['<',$1,$5]
  | expression IS NOT LESS THAN expression -> ['!<',$1,$6]
  | expression EQ expression      -> ['=?',$1,$3]
  | expression IS expression      -> ['=?',$1,$3]
  | expression NE expression      -> ['<>',$1,$3]
  | expression ISNT expression    -> ['<>',$1,$3]
  | THE name OF expression        -> ['.',$4,$1]
  | expression '.' name           -> ['.',$1,$3]
  | expression '[' integer ']'    -> ['.',$1,$3]
  | '-' expression  %prec UMINUS  -> ['-',$2]
  | '+' expression  %prec UMINUS  -> ['-',$2]
  | pattern MATCHES expression    -> ['~',$3,$1]
  | expression MATCHES pattern    -> ['~',$1,$3]
  | op '(' parameters ')'         -> ['apply',$1,$3]
  | name '(' pairs ')'            -> ['apply',$1,$3]
  | op '(' ')'                    -> ['apply',$1]
  | op                            -> ['apply',$1]
  | THE op                        -> ['apply',$1]
  | expression cond               -> ['if',$2,$1]
  | cond then                     -> ['if',$1,$2]
  | cond then else                -> ['if',$1,$2,$3]
  | '(' expressions ')'           -> $2
  | '[' parameters ']'            -> [$2]
  | '{' hash_pairs '}'            -> [$2]
  | '[' ']'                       -> []
  | '{' '}'                       -> {}
  ;

cond
  : IF expression       -> $2
  | UNLESS expression   -> ['!',$2]
  ;

then
  : THEN expression -> $2
  | block           -> $1
  ;

else
  : ELSE expression -> $2
  | ELSE block      -> $2
  ;

parameters
  : parameters ',' parameter  -> $1.concat([$3]);
  | parameter                 -> [$1]
  ;

parameter
  : expression -> $1
  ;

pairs
  : pairs nlc pair  -> $1.concat([$3])
  | pair            -> [$1]
  ;

pair
  : name ASSIGN expression -> [$1,$3]
  ;

hash_pairs
  : hash_pairs nlc hash_pair  -> $1.concat([$3])
  | hash_pair                 -> [$1]
  ;

hash_pair
  : name    ASSIGN expression -> [$1,$3]
  | string  ASSIGN expression -> [$1,$3]
  | integer ASSIGN expression -> [$1,$3]
  ;

/* Constants */

integer
  : INTEGER   -> parseInt(yytext,10)
  ;

float
  : FLOAT     -> parseFloat(yytext)
  ;

string
  : STRING    -> yytext.substr(1,yytext.length-2)
  ;

pattern
  : PATTERN   -> pattern(yytext.substr(1,yytext.length-2))
  ;

name
  : NAME      -> yytext
  ;

op
  : OP        -> yy.op[yytext]
  ;
