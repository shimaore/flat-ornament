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
%x simple frcgu

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

<simple>\w+         return (yy.valid_op && yytext in yy.valid_op) ? 'OP' : 'NAME';

<simple>\s+         /* skip whitespace */
<simple><<EOF>>     return 'EOF'
<simple>.           return yytext

/* frcgu */

"Conditions Générales d'Utilisation"  this.begin("frcgu"); return 'CGU'

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

<frcgu>"France métropolitaine"              yytext = 'fr'; return 'COUNTRY'
<frcgu>"Allemagne"                          yytext = 'de'; return 'COUNTRY'
<frcgu>"Royaume-Uni"                        yytext = 'uk'; return 'COUNTRY'
<frcgu>"Argentine"                          return 'COUNTRY'
<frcgu>"Australie"                          return 'COUNTRY'
<frcgu>"Autriche" return 'xx'
<frcgu>"Baléares" return 'xx'
<frcgu>"Belgique"                           yytext = 'be'; return 'COUNTRY'
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
<frcgu>"Suisse"                               yytext = 'ch'; return 'COUNTRY'
<frcgu>"Suède" return 'xx'
<frcgu>"Taïwan" return 'xx'
<frcgu>"Thaïlande" return 'xx'
<frcgu>"USA"                    return 'us'
<frcgu>"Vatican" return 'xx'

<frcgu>[,]          /* ignore */
<frcgu>{INTEGER}    return 'INTEGER'
<frcgu>{NAME}       return 'NAME'

<frcgu>\s+          /* skip whitespace */
<frcgu><<EOF>>     return 'EOF'
<frcgu>.           return yytext

/lex

/* operator association and precedence, if any */

%% /* grammar */

start
  : menus EOF                           { return $1 }
  | ORNAMENTS ornaments   EOF           { return $2 }
  | ORNAMENT  ornament    EOF           { return $2 }
  | STATEMENT c_statement EOF           { return $2 }
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
  : c_ornament END -> $1
  | IF c_ornament THEN c_ornament END -> $2.concat([$4])
  ;

c_ornament
  : c_ornament AND c_statement      -> $1.concat([$3])
  | c_ornament ',' c_statement      -> $1.concat([$3])
  | c_statement                     -> [$1]
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
  : countries ',' country -> $$ = $1.concat([$3])
  | country               -> $$ = [$1]
  ;

country
  : COUNTRY -> yytext
  ;

outcome
  : FREE -> [{type:'free'}]
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
