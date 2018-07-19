/* Parses flat-ornament text syntax */

%lex

FLOAT       [0-9]+"."(?:[0-9]+)?\b
INTEGER     [0-9]+
STRING1     [']([^'\r\n]*)[']
STRING2     ["]([^"\r\n]*)["]
PATTERN     [/](\d|\?|\.|\.\.|\.\.\.|…)+[/]
NAME        [A-Za-z][\w-]+

%options flex

/* Non-exclusive states */
/* %s none */
/* Exclusive states */
%x simple

%%


/* INITIAL */

"#"[^\r\n]*?[\r\n]      /* hash comments */
"menu"                  this.begin('simple'); return 'MENU'
"ornaments"             this.begin('simple'); return 'ORNAMENTS'
"ornament"              this.begin('simple'); return 'ORNAMENT'
"statement"             this.begin('simple'); return 'STATEMENT'
<<EOF>>                 return 'EOF'
.                       return yytext

/* simple */

<simple>"menu"      return 'MENU'

<simple>"if"        return 'IF'
<simple>"then"      return 'THEN'

<simple>"and"       return 'AND'
<simple>"&&"        return 'AND'

<simple>"not"       return 'NOT'
<simple>"!"         return 'NOT'

<simple>"end"       return 'END'
<simple>";"         return 'END'
<simple>"."         return 'END'

<simple>{FLOAT}     return 'FLOAT'
<simple>{INTEGER}   return 'INTEGER'
<simple>{STRING1}   return 'STRING'
<simple>{STRING2}   return 'STRING'
<simple>{PATTERN}   return 'PATTERN'

<simple>\w+         return (yy.op && yytext in yy.op) ? 'OP' : 'NAME';

<simple>\s+         /* skip whitespace */
<simple><<EOF>>     return 'EOF'
<simple>.           return yytext

/lex

/* operator association and precedence, if any */

%% /* grammar */

start
  : menus EOF                           { return $1 }
  | ORNAMENTS ornaments   EOF           { return $2 }
  | ORNAMENT  ornament    EOF           { return $2 }
  | STATEMENT c_statement EOF           { return $2 }
  ;

/* Menus build an object */

menus
  : menus menu    -> $1; $$[$2[0]] = $2[1]
  |               -> {}
  ;

menu
  : menu_label ':' ornaments  -> [$1,$3]
  ;

menu_label
  : MENU INTEGER    ->  $2
  ;

/* Ornaments are async functions */

ornaments
  : ornaments ornament -> async function () { if ('over' !== await $1.call(this)) { return await $2.call(this) } }
  |  -> yy.NOTHING
  ;

ornament
  : c_ornament END -> $1
  | IF c_ornament THEN c_ornament END -> async function() { return (await $2.call(this)) ? await $4.call(this) : yy.NOTHING }
  ;

c_ornament
  : c_ornament AND c_statement      -> async function() { return (await $1.call(this)) ? await $3.call(this) : yy.NOTHING }
  | c_ornament ',' c_statement      -> async function() { return (await $1.call(this)) ? await $3.call(this) : yy.NOTHING }
  | c_statement                     -> $1
  ;

c_statement
  : command -> $1
  ;

command
  : NOT operation   -> async function () { return !await $2.call(this) }
  | operation       -> $1
  ;

operation
  : op '(' parameters ')'   -> async function () { return $1.apply(this,$3) }
  | op '(' ')'              -> async function () { return $1.call(this) }
  | '(' op ')'              -> async function () { return $2.call(this) }
  | '(' op parameters ')'   -> async function () { return $2.apply(this,$3) }
  | op                      -> async function () { return $1.call(this) }
  ;

parameters
  : parameters ',' parameter  -> $1.concat([$3]);
  | parameter                 -> [$1]
  ;

parameter
  : integer -> $1
  | float -> $1
  | string -> $1
  | pattern -> $1
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

op
  : OP        -> yy.op[yytext]
  ;
