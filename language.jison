/* Parses flat-ornament text syntax */

%lex

%options flex

/* Non-exclusive states */
%s en fr frcgu

%%

"#"[^\r\n]*?[\r\n]      /* hash comments */
\s+                     /* skip whitespace */

[0-9]+"."(?:[0-9]+)?\b  return 'FLOAT'
[0-9]+                  return 'INTEGER'
["]([^"\r\n]*)["]       return 'STRING'
[']([^'\r\n]*)[']       return 'STRING'
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

"Conditions Générales d'Utilisation"  this.begin("frcgu"); return 'CGU'

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

<frcgu>"Les appels"                         return 'CALLS'
<frcgu>"sur le réseau"                      return 'CALLED_ONNET'
<frcgu>"vers les fixes"                     return 'CALLED_FIXED'
<frcgu>"vers les mobiles"                   return 'CALLED_MOBILE'
<frcgu>"vers les fixes et les mobiles"      return 'CALLED_FIXED_OR_MOBILE'
<frcgu>"vers"                               return 'TOWARDS'
<frcgu>"en"                                 return 'TOWARDS'
<frcgu>"Appel illimités"                    return 'UNLIMITED'
<frcgu>"dans la limite de"                  return 'ATMOST'
<frcgu>"au plus"                            return 'ATMOST'
<frcgu>"jusqu'à"                            return 'ATMOST'
<frcgu>"heures"                             return 'HOURS'
<frcgu>"mensuels"                           return 'PER_MONTH'
<frcgu>"mensuelles"                         return 'PER_MONTH'
<frcgu>"destinataires"                      return 'CALLEE'
<frcgu>"différents"                         return 'DIFFERENT'
<frcgu>"différentes"                        return 'DIFFERENT'
<frcgu>"par mois"                           return 'PER_CYCLE'
<frcgu>"par facture"                        return 'PER_CYCLE'
<frcgu>"sont gratuits"                      return 'FREE'
<frcgu>"par appel"                          return 'PER_CALL'
<frcgu>"par jour"                           return 'PER_DAY'
<frcgu>"par heure"                          return 'PER_HOUR'
<frcgu>"par semaine"                        return 'PER_WEEK'
<frcgu>"par jour de la semaine"             return 'PER_DAY_OF_WEEK'
<frcgu>"heure"                              return 'HOURS'
<frcgu>"heures"                             return 'HOURS'
<frcgu>"minute"                             return 'MINUTES'
<frcgu>"minutes"                            return 'MINUTES'
<frcgu>"seconde"                            return 'SECONDES'
<frcgu>"secondes"                           return 'SECONDES'

<frcgu>"France métropolitaine"              return 'fr'
<frcgu>"Allemagne"                          return 'de'
<frcgu>"Royaume-Uni"                        return 'uk'
<frcgu>"Argentine"                          return 'xx'
<frcgu>"Australie"                          return 'xx'
<frcgu>"Autriche" return 'xx'
<frcgu>"Baléares" return 'xx'
<frcgu>"Belgique"                              return 'be'
<frcgu>"Brésil" return 'xx'
<frcgu>"Canada" return 'xx'
<frcgu>"Chili" return 'xx'
<frcgu>"Chine" return 'xx'
<frcgu>"Chypre" return 'xx'
<frcgu>"Colombie" return 'xx'
<frcgu>"Danemark" return 'xx'
<frcgu>"Écosse" return 'xx'
<frcgu>"Espagne" return 'xx'
<frcgu>"Estonie" return 'xx'
<frcgu>"France métropolitaine" return 'xx'
<frcgu>"Grèce" return 'xx'
<frcgu>"Guam" return 'xx'
<frcgu>"Hong-Kong" return 'xx'
<frcgu>"Hongrie" return 'xx'
<frcgu>"Iles Vierges (U.S.)" return 'xx'
<frcgu>"Islande" return 'xx'
<frcgu>"Irlande" return 'xx'
<frcgu>"Irlande du Nord" return 'xx'
<frcgu>"Israël" return 'xx'
<frcgu>"Italie" return 'xx'
<frcgu>"Kazakhstan" return 'xx'
<frcgu>"Lettonie" return 'xx'
<frcgu>"Luxembourg" return 'xx'
<frcgu>"Malaisie" return 'xx'
<frcgu>"Mexique" return 'xx'
<frcgu>"Norvège" return 'xx'
<frcgu>"Nouvelle Zélande" return 'xx'
<frcgu>"Panama" return 'xx'
<frcgu>"Pays Bas" return 'xx'
<frcgu>"Pays de Galles" return 'xx'
<frcgu>"Pologne" return 'xx'
<frcgu>"Portugal" return 'xx'
<frcgu>"Pérou" return 'xx'
<frcgu>"Russie" return 'xx'
<frcgu>"Singapour" return 'xx'
<frcgu>"Slovaquie" return 'xx'
<frcgu>"Suisse"                 return 'ch'
<frcgu>"Suède" return 'xx'
<frcgu>"Taïwan" return 'xx'
<frcgu>"Thaïlande" return 'xx'
<frcgu>"USA"                    return 'us'
<frcgu>"Vatican" return 'xx'

<frcgu>[;]                      return ';'
<frcgu>[,]                      /* ignore */
<frcgu>[.]                      return '.'
<frcgu>[\w-]+                      return 'NAME'

[;]                     this.popState(); return ';'
[.]                     this.popState(); return '.'

\w+                     return (yy.valid_op && yytext in yy.valid_op) ? 'OP' : yytext;

<<EOF>>                 return 'EOF'

"{".*"}"                return 'JSON'
.                       return yytext
/lex

/* operator association and precedence, if any */

%% /* grammar */

start
  : menus EOF                           { return $1 }
  | COMPILE ORNAMENTS ornaments EOF     { return $3 }
  | COMPILE ORNAMENT ornament EOF       { return $3 }
  | COMPILE STATEMENT c_statement EOF   { return $3 }
  | COMPILE STATEMENT fr_statement EOF  { return $3 }
  | COMPILE STATEMENT en_statement EOF  { return $3 }
  | CGU fr_cgu EOF                      { return $2 }
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
  : c_ornament ';' -> $1
  | c_ornament '.' -> $1
  | fr_ornament '.' -> $1
  | en_ornament '.' -> $1
  | IF c_ornament THEN c_ornament ';' -> $2.concat([$4])
  | IF c_ornament THEN c_ornament '.' -> $2.concat([$4])
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

fr_cgu
  : fr_cgu fr_cgu_sentence -> $1.concat([$2])
  | -> /* hide_emergency */ [[{type:'called_emergency'}, {type:'hide_call'}, {type:'stop'}]]
  ;

fr_cgu_sentence
  : sentence '.' -> [{type:'reset_up_to'}].concat($1,[{type:'stop'}])
  ;

sentence
  : CALLS conditions outcomes -> $2.concat($3)
  | CALLS conditions outcomes conditions -> $2.concat($4, $3)
  | CALLS outcomes conditions -> $3.concat($2)
  ;

conditions
  : conditions condition -> $1.concat($2)
  | condition -> $1
  ;

outcomes
  : outcomes outcome -> $1.concat($2)
  | outcome -> $1
  ;

condition
  : CALLED_ONNET            -> [{type:'called_onnet'}]
  | CALLED_ONNET NAME       -> [{type:'called_onnet'}]
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

name
  : NAME -> yytext
  ;

callees
  : integer CALLEE -> $1
  ;

duration
  : integer time_unit -> $1 * $2
  ;

period
  : PER_DAY       -> 'day'
  | PER_HOUR      -> 'hour'
  | PER_WEEK      -> 'week'
  | DAY_OF_WEEK   -> 'day-of-week'
  ;

time_unit
  : SECONDS -> 1
  | MINUTES -> 60
  | HOURS   -> 3600
  ;

countries
  : countries ',' country -> $1.concat([$3])
  | country -> [$1]
  ;

country
  : fr -> 'fr'
  | be -> 'be'
  | ch -> 'ch'
  ;

outcome
  : FREE -> [{type:'free'}]
  ;
