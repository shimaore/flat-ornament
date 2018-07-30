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

\s+             /* skip */

"if"            return 'IF'
"unless"        return 'UNLESS'
"then"          return 'THEN'
"else"          return 'ELSE'
"and"           return 'AND'
"or"            return 'OR'
"not"           return 'NOT'
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

{FLOAT}         return 'FLOAT'
{INTEGER}       return 'INTEGER'
{STRING1}       return 'STRING'
{STRING2}       return 'STRING'
{PATTERN}       return 'PATTERN'
{NAME}          return (yy.op && yytext in yy.op) ? 'OP' : 'NAME'

"#"[^\r\n]+[\r\n]  /* comment */

<<EOF>>         return 'EOF'
.               return yytext

/lex

%{

const Immutable = require('immutable');
const pattern = require ('./pattern');
const is_function = function (f) { return 'function' === typeof f }
const reject_function = function (n,v) { if(is_function(v)) throw new Error(`Parameter ${n} might not be a function.`); return v; }
const need_function = function (n,f) { if(!is_function(f)) throw new Error(`${n} should be a function.`); return f; }

%}

/* operator association and precedence, if any */

%left ','
%right POSTPONE
%right ASSIGN
%right IF UNLESS
%left THEN ELSE
%left OR
%left AND
%left IS ISNT '~' EQ NE
%left '<' '>' GE LE
/* bitwise */
%left '+' '-'
%left '*' '/' '%'
%right NOT UMINUS
%left OF '[' '.'

%% /* grammar */

start
  : expressions EOF  { return function () { return $1(this,Immutable.Map()) /* evaluate */ } }
  |                  { return function () {} }
  ;

expressions
  : assignment ',' expressions     -> async function (rtx,ctx) { var ctx = await $1(rtx,ctx); return $3(rtx,ctx); }
  | expression ',' expressions     -> async function (rtx,ctx) { await $1(rtx,ctx); return $3(rtx,ctx); }
  | expression -> $1
  ;

assignment
  : name ASSIGN expression  -> async function (rtx,ctx) { var name = $1; var val = await $3(rtx,ctx); return ctx.set(name,val); }
  ;

expression
  : name                          -> function (rtx,ctx) { return ctx.get($1) }
  | float                         -> function (rtx,ctx) { return $1 }
  | integer                       -> function (rtx,ctx) { return $1 }
  | string                        -> function (rtx,ctx) { return $1 }
  | TRUE                          -> function (rtx,ctx) { return true }
  | FALSE                         -> function (rtx,ctx) { return false }
  | POSTPONE expression           -> function (rtx,ctx) { return $2 }
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
  | THE name OF expression        -> async function (rtx,ctx) { var a = await $4(rtx,ctx); if ($2 === 'length') { return a.length }; if ($2 === 'size') { return a.size }; return a.get($2) }
  | expression '.' name           -> async function (rtx,ctx) { var a = await $1(rtx,ctx); if ($3 === 'length') { return a.length }; if ($2 === 'size') { return a.size }; return a.get($3) }
  | expression '[' integer ']'    -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return a[$3] }
  | '-' expression  %prec UMINUS  -> async function (rtx,ctx) { return - await $2(rtx,ctx) }
  | '+' expression  %prec UMINUS  -> async function (rtx,ctx) { return + await $2(rtx,ctx) }
  | pattern  expresion            -> async function (rtx,ctx) { var a = await $2(rtx,ctx); return (typeof a === 'string') && a.match($1); }
  | expression '~' pattern        -> async function (rtx,ctx) { var a = await $1(rtx,ctx); return (typeof a === 'string') && a.match($3); }
  | op '(' parameters ')'         -> async function (rtx,ctx) { var args  = await Promise.all($3.map( async function (a) { return await a(rtx,ctx) })); return $1.apply(rtx,args); }
  | name '(' pairs ')'            -> async function (rtx,ctx) { var f = need_function($1,ctx.get($1)); var pairs = await Promise.all($3.map( async function ([k,a]) { var v = await a(rtx,ctx); return [k,reject_function(k,v)] })); return f(rtx,Immutable.Map(pairs)); }
  | op '(' ')'                    -> function (rtx,ctx) { return $1.apply(rtx); }
  | op                            -> function (rtx,ctx) { return $1.apply(rtx); }
  | THE op                        -> function (rtx,ctx) { return $2.apply(rtx); }
  | IF expression THEN expression                 -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); if ( cond) return $4(rtx,ctx); }
  | UNLESS expression THEN expression             -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); if (!cond) return $4(rtx,ctx); }
  | expression IF expression                      -> async function (rtx,ctx) { var cond = await $3(rtx,ctx); if ( cond) return $1(rtx,ctx); }
  | expression UNLESS expression                  -> async function (rtx,ctx) { var cond = await $3(rtx,ctx); if (!cond) return $1(rtx,ctx); }
  | IF expression THEN expression ELSE expression     -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); if ( cond) { return $4(rtx,ctx) } else { return $6(rtx,ctx) } }
  | UNLESS expression THEN expression ELSE expression -> async function (rtx,ctx) { var cond = await $2(rtx,ctx); if (!cond) { return $4(rtx,ctx) } else { return $6(rtx,ctx) } }
  | '(' expressions ')'           -> $2
  | '[' parameters ']'            -> async function (rtx,ctx) { return await Promise.all($2.map( async function (a) { return await a(rtx,ctx) })); }
  | '{' hash_pairs '}'            -> async function (rtx,ctx) { var pairs = await Promise.all($2.map( async function ([k,a]) { var v = await a(rtx,ctx); return [k,v] })); return Immutable.Map(pairs) }
  | '[' ']'                       -> function (rtx,ctx) { return [] }
  | '{' '}'                       -> function (rtx,ctx) { return Immutable.Map() }
  ;

parameters
  : parameters ',' parameter  -> $1.concat([$3]);
  | parameter                 -> [$1]
  ;

parameter
  : expression -> $1
  ;

pairs
  : pairs ',' pair  -> $1.concat([$3])
  | pair            -> [$1]
  ;

pair
  : name ASSIGN expression -> [$1,$3]
  ;

hash_pairs
  : hash_pairs ',' hash_pair  -> $1.concat([$3])
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
