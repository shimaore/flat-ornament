/* Parses flat-ornament text syntax */

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
    if (new_indent  >  top_indent) { yy.indent.unshift(new_indent); return 'INDENT' }
    if (new_indent  <  top_indent) { yy.indent.shift(); this.unput(yytext); return 'OUTDENT' }
  %}

[\r\n][ ]*(?![\r\n]|"else")      %{
    if(!yy.indent) yy.indent = [0]
    var new_indent = yytext.length-1
    var top_indent = yy.indent[0]
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

const pattern = require ('./pattern');
const is_function = function (f) { return 'function' === typeof f }
const reject_function = function (n,v) { if(is_function(v)) throw new Error(`Parameter ${n} might not be a function.`); return v; }
const need_function = function (n,f) { if(!is_function(f)) throw new Error(`${n} should be a function.`); return f; }
const setit = function(v,ctx) { ctx.set('it',v); return v; }

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
  : expressions EOF { return function () { return $1(this,new Map()) /* evaluate */ } }
  ;

expressions
  : assignment nlc expressions -> async function (rtx,ctx) { var ctx = await $1(rtx,ctx); return $3(rtx,ctx); }
  | expression nlc expressions -> async function (rtx,ctx) { await $1(rtx,ctx); return $3(rtx,ctx); }
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
  : name ASSIGN expression  -> async function (rtx,ctx) { var name = $1; var val = await $3(rtx,ctx); return new Map(ctx).set(name,val); }
  ;

block
  : INDENT block-lines OUTDENT -> $2
  ;

block-lines
  : expression nl block-lines -> async function (rtx,ctx) { await $1(rtx,ctx); return $3(rtx,ctx); }
  | expression nl -> $1
  | expression -> $1
  ;

expression
  : name                          -> function (rtx,ctx) { return ctx.get($1) }
  | float                         -> function (rtx,ctx) { return $1 }
  | integer                       -> function (rtx,ctx) { return $1 }
  | string                        -> function (rtx,ctx) { return $1 }
  | TRUE                          -> function (rtx,ctx) { return true }
  | FALSE                         -> function (rtx,ctx) { return false }
  | IT                            -> function (rtx,ctx) { return ctx.get('it') }
  | POSTPONE expression           -> function (rtx,ctx) { return $2 }
  | POSTPONE expressions-block    -> function (rtx,ctx) { return $2 }
  | expression AND expression     -> async function (rtx,ctx) { var cond = await $1(rtx,ctx); return cond && $3(rtx,ctx) }
  | expression OR  expression     -> async function (rtx,ctx) { var cond = await $1(rtx,ctx); return cond || $3(rtx,ctx) }
  | NOT expression                -> async function (rtx,ctx) { return ! await $2(rtx,ctx) }
  | expression '+' expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a + await $3(rtx,ctx) }
  | expression '-' expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a - await $3(rtx,ctx) }
  | expression '*' expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a * await $3(rtx,ctx) }
  | expression '/' expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a / await $3(rtx,ctx) }
  | expression '%' expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a % await $3(rtx,ctx) }
  | expression '>' expression                 -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a > await $3(rtx,ctx) }
  | expression GE expression                  -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a >= await $3(rtx,ctx) }
  | expression IS GREATER THAN expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a > await $5(rtx,ctx) }
  | expression IS NOT GREATER THAN expression -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return !(a > await $5(rtx,ctx)) }
  | expression '<' expression                 -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a < await $3(rtx,ctx) }
  | expression LE expression                  -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a <= await $3(rtx,ctx) }
  | expression IS LESS THAN expression     -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a < await $5(rtx,ctx) }
  | expression IS NOT LESS THAN expression -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return !(a < await $5(rtx,ctx)) }
  | expression EQ expression      -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a === await $3(rtx,ctx) }
  | expression IS expression      -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a === await $3(rtx,ctx) }
  | expression NE expression      -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a !== await $3(rtx,ctx) }
  | expression ISNT expression    -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a !== await $3(rtx,ctx) }
  | THE name OF expression        -> async function (rtx,ctx) { var a = await $4(rtx,ctx); if ($2 === 'length') { return setit(a.length,ctx) }; if ($2 === 'size') { return setit(a.size,ctx) }; return setit(a.get($2),ctx) }
  | expression '.' name           -> async function (rtx,ctx) { var a = await $1(rtx,ctx); if ($3 === 'length') { return a.length }; if ($2 === 'size') { return a.size }; return a.get($3) }
  | expression '[' integer ']'    -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a[$3] }
  | '-' expression  %prec UMINUS  -> async function (rtx,ctx) { return - await $2(rtx,ctx) }
  | '+' expression  %prec UMINUS  -> async function (rtx,ctx) { return + await $2(rtx,ctx) }
  | pattern MATCHES expression    -> async function (rtx,ctx) { var a = await $2(rtx,ctx); return (typeof a === 'string') && a.match($1); }
  | expression MATCHES pattern    -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return (typeof a === 'string') && a.match($3); }
  | op '(' parameters ')'         -> async function (rtx,ctx) { var args  = await Promise.all($3.map( async function (a) { return await a(rtx,ctx) })); return $1.apply(rtx,args); }
  | name '(' pairs ')'            -> async function (rtx,ctx) { var f = need_function($1,ctx.get($1)); var pairs = await Promise.all($3.map( async function ([k,a]) { var v = await a(rtx,ctx); return [k,reject_function(k,v)] })); return f(rtx,new Map(pairs)); }
  | op '(' ')'                    -> function (rtx,ctx) { return $1.apply(rtx); }
  | op                            -> function (rtx,ctx) { return $1.apply(rtx); }
  | THE op                        -> function (rtx,ctx) { return setit($2.apply(rtx),ctx); }
  | expression cond               -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); if (cond) return $1(rtx,ctx); }
  | cond then                     -> async function (rtx,ctx) { var cond = await $1(rtx,ctx); if (cond) return $2(rtx,ctx); }
  | cond then else                -> async function (rtx,ctx) { var cond = await $1(rtx,ctx); if (cond) { return $2(rtx,ctx) } else { return $3(rtx,ctx) } }
  | '(' expressions ')'           -> $2
  | '[' parameters ']'            -> async function (rtx,ctx) { return await Promise.all($2.map( async function (a) { return await a(rtx,ctx) })); }
  | '{' hash_pairs '}'            -> async function (rtx,ctx) { var pairs = await Promise.all($2.map( async function ([k,a]) { var v = await a(rtx,ctx); return [k,v] })); return new Map(pairs) }
  | '[' ']'                       -> function (rtx,ctx) { return [] }
  | '{' '}'                       -> function (rtx,ctx) { return new Map() }
  ;

cond
  : IF expression       -> $2
  | UNLESS expression   -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); return !cond; }
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
