/* Parses flat-ornament text syntax */

%lex

FLOAT       [0-9]+"."(?:[0-9]+)?\b
INTEGER     [0-9]+
STRING1     [']([^'\r\n]*)[']
STRING2     ["]([^"\r\n]*)["]
PATTERN     [/](\d|\?|\.|\.\.|\.\.\.|…)+[/]
NAME        [A-Za-z][\w-]*

%token OP NAME

%options flex

/* Exclusive states */
%x simple frcgu

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
"true"          return 'TRUE'
"false"         return 'FALSE'
"greater"       return 'GREATER'
"smaller"       return 'SMALLER'
"than"          return 'THAN'
"the"           return 'THE'
"of"            return 'OF'

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

%}

/* operator association and precedence, if any */

%right IF UNLESS
%left THEN ELSE
%left AND
%left OR
%left NOT
%left '<' '>' IS ISNT '~' EQ NE
%left '+' '-'
%left '*' '/' '%'
%left '^'
%left '['
%left UMINUS
%left OF

%% /* grammar */

start
  : expressions EOF  { return function () { return $1.call(this,Immutable.Map()) /* evaluate */ } }
  |                  { return function () {} }
  ;

expressions
  : assignment ',' expressions     -> async function (ctx) { var ctx = await $1.call(this,ctx); return $3.call(this,ctx); }
  | expression ',' expressions     -> async function (ctx) { var it = await $1.call(this,ctx); return $3.call(this,ctx); }
  | expression -> $1
  | '{' expressions '}' -> $2
  ;

assignment
  : name '=' expression  -> async function (ctx) { var name = $1; var val = await $3.call(this,ctx); return ctx.set(name,val); }
  ;

expression
  : name                          -> function (ctx) { return ctx.get($1) }
  | float                         -> function (ctx) { return $1 }
  | integer                       -> function (ctx) { return $1 }
  | string                        -> function (ctx) { return $1 }
  | TRUE                          -> function (ctx) { return true }
  | FALSE                         -> function (ctx) { return false }
  | expression AND expression     -> async function (ctx) { var cond = await $1.call(this,ctx); return cond && $3.call(this,ctx) }
  | expression OR  expression     -> async function (ctx) { var cond = await $1.call(this,ctx); return cond || $3.call(this,ctx) }
  | NOT expression                -> async function (ctx) { return ! await $2.call(this,ctx) }
  | expression '+' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a + await $3.call(this,ctx) }
  | expression '-' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a - await $3.call(this,ctx) }
  | expression '*' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a * await $3.call(this,ctx) }
  | expression '/' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a / await $3.call(this,ctx) }
  | expression '%' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a % await $3.call(this,ctx) }
  | expression '>' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a > await $3.call(this,ctx) }
  | expression IS GREATER THAN expression -> async function (ctx) { var a = await $1.call(this,ctx); return a > await $5.call(this,ctx) }
  | expression IS NOT GREATER THAN expression -> async function (ctx) { var a = await $1.call(this,ctx); return !(a > await $5.call(this,ctx)) }
  | expression '<' expression     -> async function (ctx) { var a = await $1.call(this,ctx); return a < await $3.call(this,ctx) }
  | expression IS SMALLER THAN expression -> async function (ctx) { var a = await $1.call(this,ctx); return a < await $5.call(this,ctx) }
  | expression IS NOT SMALLER THAN expression -> async function (ctx) { var a = await $1.call(this,ctx); return !(a < await $5.call(this,ctx)) }
  | expression EQ expression      -> async function (ctx) { var a = await $1.call(this,ctx); return a === await $3.call(this,ctx) }
  | expression NE expression      -> async function (ctx) { var a = await $1.call(this,ctx); return a !== await $3.call(this,ctx) }
  | expression IS expression      -> async function (ctx) { var a = await $1.call(this,ctx); return a === await $3.call(this,ctx) }
  | expression ISNT expression    -> async function (ctx) { var a = await $1.call(this,ctx); return a !== await $3.call(this,ctx) }
  | THE name OF expression        -> async function (ctx) { var a = await $4.call(this,ctx); if (a.hasOwnProperty($2)) { return a[$2] }; if ($2 === 'length') { return a.length } }
  | expression '[' integer ']'    -> async function (ctx) { var a = await $1.call(this,ctx); if (a.hasOwnProperty($3)) { return a[$3] }; }
  | '-' expression  %prec UMINUS  -> async function (ctx) { return - await $2.call(this,ctx) }
  | '+' expression  %prec UMINUS  -> async function (ctx) { return + await $2.call(this,ctx) }
  | pattern  expresion            -> async function (ctx) { var a = await $1.call(this,ctx); return (typeof a === 'string') && a.match($2); }
  | expression '~' pattern        -> async function (ctx) { var a = await $1.call(this,ctx); return (typeof a === 'string') && a.match($3); }
  | op '(' parameters ')'         -> async function (ctx) { var args = await Promise.all($3.map( (a) => a.call(this,ctx) )); return $1.apply(this,args); }
  | op '(' ')'                    -> function (ctx) { return $1.call(this); }
  | op                            -> function (ctx) { return $1.call(this); }
  | IF expression THEN expression                 -> async function (ctx) { var cond = await $2.call(this,ctx); if (cond) return $4.call(this,ctx); }
  | expression IF expression                      -> async function (ctx) { var cond = await $3.call(this,ctx); if (cond) return $1.call(this,ctx); }
  | expression UNLESS expression                  -> async function (ctx) { var cond = await $3.call(this,ctx); if (!cond) return $1.call(this,ctx); }
  | IF expression THEN expression ELSE expression -> async function (ctx) { var cond = await $2.call(this,ctx); if (cond) { return $4.call(this,ctx) } else { return $6(ctx) } }
  | '(' expression ')'            -> $2
  | '[' parameters ']'            -> async function (ctx) { return await Promise.all($2.map( (a) => a.call(this,ctx) )); }
  | '[' ']'                       -> function (ctx) { return [] }
  ;

parameters
  : parameters ',' parameter  -> $1.concat([$3]);
  | parameter                 -> [$1]
  ;

parameter
  : expression -> $1
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
