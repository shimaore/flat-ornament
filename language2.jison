/* Parses flat-ornament text syntax */

%lex

FLOAT       [0-9]+"."(?:[0-9]+)?\b
INTEGER     [0-9]+
STRING1     [']([^'\r\n]*)[']
STRING2     ["]([^"\r\n]*)["]
PATTERN     [/](\d|\?|\.|\.\.|\.\.\.|…)+[/]
NAME        [A-Za-z][\w-]+

%options flex

/* Exclusive states */
%x simple frcgu

%%


/* INITIAL */

\s+             /* skip */

"if"            return 'IF'
"then"          return 'THEN'
"else"          return 'ELSE'
"it"            return 'IT'
"and"           return 'AND'
"or"            return 'OR'
"not"           return 'NOT'

{FLOAT}         return 'FLOAT'
{INTEGER}       return 'INTEGER'
{STRING1}       return 'STRING'
{STRING2}       return 'STRING'
{PATTERN}       return 'PATTERN'
{NAME}          return (yy.valid_op && yytext in yy.valid_op) ? 'OP' : 'NAME'

<<EOF>>                 return 'EOF'
.                       return yytext

/lex

/* operator association and precedence, if any */

%left AND
%left OR
%left NOT
%left '+' '-'
%left '*' '/'
%left '^'
%right '!'
%right '%'
%left UMINUS

%% /* grammar */

start
  : expressions -> $1(Immutable.Map()) /* evaluate */
  ;

expressions
  : expressions expression -> (ctx) => it = await $1(ctx); await $2(ctx.set('it', it))
  | -> (ctx) => undefined
  ;

expression
  : NAME '=' expression expressions -> name = $1; (ctx) => $4(ctx.set(name,await $2(ctx)))
  | IT -> (ctx) => ctx.get('it')
  | NAME -> name = $1; (ctx) => ctx.get(name)
  | number
  | boolean
  ;

boolean
  : NOT boolean -> (ctx) => ! $2(ctx)
  | boolean AND boolean -> (ctx) => $1(ctx) && $3(ctx)
  | boolean OR boolean -> (ctx) => $1(ctx) && $3(ctx)
  | boolean_constant -> (ctx) => $1
  | operation -> [name,args] = $1; fun = yy.valid_op[name]; (ctx) => fun.call this, args.map (a) => await a(ctx)
  ;

boolean_constant
  : true -> true
  | false -> false
  ;

true
  : TRUE
  | NOT false
  | true OR boolean
  | boolean OR true
  ;

false
  : FALSE
  | NOT true
  | false AND boolean
  | boolean AND false
  ;

numerical
  : number -> (ctx) => $1
  | numerical '+' numerical -> (ctx) => $1(ctx) + $3(ctx)
  | numerical '*' numerical -> (ctx) => $1(ctx) * $3(ctx)
  | numerical '-' numerical -> (ctx) => $1(ctx) - $3(ctx)
  | '-' numerical -> () => - $2(ctx) %prec UMINUS
  | '(' numerical ')' -> $2
  ;

/* constants */
number
  : float -> $1
  | integer -> $1
  | number '+' number -> $1 + $3
  | number '*' number -> $1 + $3
  | number '-' number -> $1 - $3
  | '-' number -> - $2 %prec UMINUS
  | '(' number ')' -> $2
  ;


operation
  : OP '(' parameters ')'   -> [$1,$3]
  | OP '(' ')'              -> [$1,[]]
  | '(' OP ')'              -> [$1,[]]
  | '(' OP parameters ')'   -> [$2,$3]
  | OP                      -> [$1]
  ;

parameters
  : parameters ',' parameter  -> $1.concat([$3]);
  | parameter                 -> [$1]
  ;

parameter
  : expression -> $1
  ;

condition
  : CALLED_ONNET            -> [{type:'called_onnet'}]
  | CALLED_ONNET NAME       -> [{type:'called_onnet'}] /* "sur le réseau K-net" */
  | CALLED_FIXED            -> [{type:'called_fixed'}]
  | CALLED_FIXED_OR_MOBILE  -> [{type:'called_fixed_or_mobile'}]
  | CALLED_MOBILE           -> [{type:'called_mobile'}]
  | TOWARDS countries       -> [{type:'called_country',param:$2}]
  | ATMOST callees                 -> name = yy.new_name(); $$ = [{type:'count_called',param:name},          {type:'at_most',params:[$2,name]}]
  | ATMOST callees name            -> name = 'callee_'+$3;  $$ = [{type:'count_called',param:name},          {type:'at_most',params:[$2,name]}]
  | ATMOST callees name PER_CYCLE  -> name = 'callee_'+$3;  $$ = [{type:'count_called',param:name},          {type:'at_most',params:[$2,name]}]
  | ATMOST callees period          -> name = yy.new_name(); $$ = [{type:'count_called_per',params:[name,$3]},{type:'at_most',params:[$2,name]}]
  | ATMOST callees name period     -> name = 'callee_'+$3;  $$ = [{type:'count_called_per',params:[name,$4]},{type:'at_most_per',params:[$2,name,$4]}]
  | ATMOST duration PER_CALL       ->                       $$ = [{type:'per_call_up_to',param:$2}]
  | ATMOST duration PER_CYCLE      -> name = yy.new_name(); $$ = [{type:'increment_duration',param:name},{type:'up_to',params:[$2,name]}]
  | ATMOST duration name PER_CYCLE -> name = $3;            $$ = [{type:'increment_duration',param:name},{type:'up_to',params:[$2,name]}]
  | ATMOST duration name period    -> name = $3;            $$ = [{type:'increment_duration_per',params:[name,$4]},{type:'up_to_per',params:[$2,name,$4]}]
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
  : PATTERN   -> yytext.substr(1,yytext.length-2)
  ;

name
  : NAME      -> yytext
  ;
