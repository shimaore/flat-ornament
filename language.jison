%lex

%options flex
%s en fr

%%

"#"[^\r\n]*?[\r\n]      /* hash comments */
\s+                     /* skip whitespace */

[0-9]+"."(?:[0-9]+)?\b  return 'FLOAT'
[0-9]+                  return 'INTEGER'
["]([^"\r\n]*)["]       return 'STRING'
[']([^"\r\n]*)[']       return 'STRING'
[/](\d|\?|\.|\.\.|\.\.\.|…)+[/] return 'PATTERN'

"menu"                  return 'MENU'

"and"                   return 'AND'
"&&"                    return 'AND'

"("                     return '('
")"                     return ')'
"["                     return '['
"]"                     return ']'
"not"                   return 'NOT'
"!"                     return 'NOT'
":"                     return ':'

[;]                     this.popState(); return 'ORNAMENT_END'
[.]                     this.popState(); return 'ORNAMENT_END'

"si"                return 'IF'
"Si"                return 'IF'
"if"                return 'IF'
"If"                return 'IF'
"alors"             return 'THEN'
"then"              return 'THEN'

"Efface"           this.begin("fr"); return 'CLEAR'
"Clear"            this.begin("en"); return 'CLEAR'
"Utilise"          this.begin("fr"); return 'USE'
"Use"              this.begin("en"); return 'USE'
"Va"               this.begin("fr"); return 'GO'

<fr>[Ee]"fface"     return 'CLEAR'
<en>[Cc]"lear"      return 'CLEAR'
<fr>[Uu]"tilise"    return 'USE'
<en>[Uu]"se"        return 'USE'
<fr>[Vv]"a"         return 'GO'

<fr>"indications"              return 'TAGS'
<en>"tags"                     return 'TAGS'
<fr>"centre"\s+"d'appel"       return 'CALL_CENTER'
<en>"call-center"              return 'CALL_CENTER'
<fr>"utilisateur"              return 'USER'
<en>"user"                     return 'USER'
<fr>"finir"                    return 'STOP'
<fr>"sonnerie"                 return 'RINGER'
<fr>"appel"                    return 'CALL'
<en>"call"                     return 'CALL'

<en>"anonymous"                return 'ANONYMOUS'
<fr>"anonyme"                  return 'ANONYMOUS'

<en>"the"                                   return 'THE'
<fr>"le" return 'THE'
<fr>"la" return 'THE'
<fr>"l'" return 'THE'
<fr>"les" return 'THE'
<en>"of"                                    return 'OF'
<fr>"du"|"de"\s+"la"|"des"|"de"\s+"l'"      return 'OF_THE'
<fr>"pour"                                  return 'FOR'
<en>"for"                                   return 'FOR'
<en>"a"|"an"|"some"                         return 'SOME'
<fr>"un"|"une"|"des"                        return 'SOME'
<fr>"à"\s+"la"|"au"|"à"\s+"l'"              return 'TO_THE'
<en>"to"                                    return 'TO'

\w+                     return (yytext in yy.valid_op) ? 'OP' : yytext;

<<EOF>>                 return 'EOF'

"{".*"}"                return 'JSON'
.                       return yytext
/lex

%%

start
  : menus EOF                           { return $1 }
  | COMPILE ORNAMENTS ornaments EOF     { return $3 }
  | COMPILE ORNAMENT ornament EOF       { return $3 }
  | COMPILE STATEMENT c_statement EOF   { return $3 }
  | COMPILE STATEMENT fr_statement EOF  { return $3 }
  | COMPILE STATEMENT en_statement EOF  { return $3 }
  ;

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

ornaments
  : ornaments ornament -> $1.concat([$2])
  |  -> []
  ;

ornament
  : c_ornament ORNAMENT_END -> $1
  | fr_ornament ORNAMENT_END -> $1
  | en_ornament ORNAMENT_END -> $1
  | IF c_ornament THEN c_ornament ORNAMENT_END -> $2.concat([$4])
  | IF fr_ornament THEN fr_ornament ORNAMENT_END -> $2.concat([$4])
  | IF en_ornament THEN en_ornament ORNAMENT_END -> $2.concat([$4])
  ;

c_ornament
  : c_ornament AND c_statement      -> $1.concat([$3])
  | c_ornament ',' c_statement      -> $1.concat([$3])
  | c_statement                     -> [$1]
  ;

fr_ornament
  : fr_ornament ',' fr_statement    -> $1.concat([$3])
  | fr_statement                    -> [$1]
  ;

en_ornament
  : en_ornament ',' en_statement    -> $1.concat([$3])
  | en_statement                    -> [$1]
  ;

c_statement
  : command -> $1
  ;

command
  : NOT operation   -> $2; $$.not = true
  | operation       -> $1
  ;

operation
  : OP '(' parameters ')'   -> {type:$1,params:$3}
  | OP '(' ')'              -> {type:$1}
  | '(' OP ')'              -> {type:$2}
  | '(' OP parameters ')'   -> {type:$2,params:$3}
  | OP                      -> {type:$1}
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

fr_statement
  : fr_command -> $1
  ;

fr_command
  : CLEAR THE TAGS OF_THE CALL_CENTER -> {type:'clear_call_center_tags'}
  | CLEAR THE TAGS OF_THE USER -> {type:'clear_user_tags'}
  | CLEAR THE TAGS USER -> {type:'clear_user_tags'}
  | GO TO_THE MENU integer -> {type:'goto_menu',params:[$4]}
  | EXECUTE operation -> $2
  ;

en_statement
  : en_command -> $1
  ;

en_command
  : CLEAR CALL_CENTER TAGS  -> {type:'clear_call_center_tags'}
  ;
