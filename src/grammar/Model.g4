grammar Model;

model:
  modelThings
  EOF
;

modelThings:
  modelThing*
;

modelThing:
  packageDeclaration
|  importDeclaration
|  annotationDeclaration
|  topDeclaration
;


packageDeclaration:
  'package' qualifiedName '{' modelThings '}'
| 'package' qualifiedName modelThings
;

importDeclaration:
  'import' qualifiedName ('.' '*')? 
;

annotationDeclaration:
  'annotation' Identifier ':' type
;

annotation:
  '@' Identifier ('(' expression ')')?
;

topDeclaration:
  annotation* entityDeclaration
| annotation* memberDeclaration
;

entityDeclaration:
  ('class'|'assoc'|Identifier) Keyword? Identifier typeParameters? extending? 
  ('{' block '}')?
;

Keyword:
  '<' Identifier '>'
;

typeParameters:
  '[' typeParameter (',' typeParameter)* ']'
;

typeParameter:
  Identifier (':' typeBound)?
;

typeBound:
  type ('+' type)*
;
      
extending:
  'extends' type (',' type)*
;

block: 
  blockDeclaration* 
;

blockDeclaration:
  annotation* memberDeclaration
  ;

memberDeclaration:
    typeDeclaration
  | entityDeclaration
  | propertyDeclaration
  | functionDeclaration
  | constraint 
  | expression
  ;

typeDeclaration:
  'type' Identifier (typeParameters? '=' type )?
;

propertyDeclaration:
  propertyModifier* Identifier ':' type multiplicity? (('='|':=') expression)?
;

propertyModifier:
  'part'
| 'var'
| 'val'
| 'ordered'
| 'unique'
| 'source'
| 'target'
;

functionDeclaration:
  'fun' Identifier typeParameters? ('(' paramList ')')? (':' type)?
    functionSpecification*
  ('{' block '}')?
;

paramList:
  param (',' param)*
;

param:
  Identifier ':' type
;

functionSpecification:
  'pre'  expression 
| 'post' expression   
;

constraint:
  'req' (Identifier ':')?  expression
;

multiplicity:
  '[' expressionOrStar (',' expressionOrStar)? ']'
;

expressionOrStar:
  expression
| '*'
;

type:
  primitiveType                   # PrimType
| classIdentifier typeArguments?  # IdentType
| classIdentifier ('[' ']')+      # ArrayType
| type ('*' type)+                # CartesianType
| type '->' type                  # FuncType
| '(' type ')'					  # ParenType
| '{|' Identifier ':' type  SUCHTHAT expression '|}' # SubType 
;

primitiveType:
    'Bool'
  | 'Char'
  | 'Int'       // Scala bigint (arbitrary precision)
  | 'Real'      // double
  | 'String'
  | 'Unit'
  | 'Time'
  | 'Duration'
  ;

classIdentifier:
  qualifiedName
| 'Class'
| collectionKind
;

collectionKind:
  'Set'
| 'OSet'
| 'Bag'
| 'Seq' 
;

typeArguments:
    '[' type (',' type)* ']'
  ;

expression: 
    classIdentifier typeArguments '(' argumentList? ')' #ConstructorAppExp1
  | '(' expression ')' #ParenExp
  | 'Tuple' '(' expression (',' expression)+ ')' #TupleExp
  | literal #LiteralExp
  | Identifier #IdentExp
  | primitiveType #IdentExp
  | expression '.' ThisLiteral #ThisOuterExp
  | expression '.' Identifier #DotExp
  | type '.' 'class' #ClassExp 
  | expression '(' argumentList? ')' #AppExp
  | type '(' argumentList? ')' #ConstructorAppExp2
  | expression '[' positionalArgumentList ']' #IndexExp
  | '!' expression #NotExp
  | '{' block  '}' {$ctx.parent instanceof ModelParser.ModelContext}? #BlockExp
  | 'if' expression 'then' expression ('else' expression)? #IfExp
  | 'match' expression 'with' match+  #MatchExp
  | 'while' expression 'do' expression  #WhileExp
  | 'for' pattern 'in' expression 'do' expression # ForExp 
  | collectionKind '{' expressionList? '}' #SetEnumExp
  | collectionKind '{' expression '..' expression '}' #SetRngExp
  | collectionKind '{' expression '|' rngBindingList SUCHTHAT expression '}' #SetCompExp 
  | expression 'is' type # TypeCheckExp
  | expression 'as' type # TypeCastExp
  | expression ('*'|'/'|'%'|'inter'|'\\'|'++'|'#'|'^') expression #BinOp1Exp
  | expression ('+'|'-'|'union') expression #BinOp2Exp
  | expression ('<=' | '>=' | '<' | '>' | '=' | '!=' | 'isin'|'!isin'|'subset'|'psubset') expression #BinOp3Exp
  | expression '&&' expression #AndExp
  | expression '||' expression #OrExp
  | expression ('=>' | '<=>') expression #IFFExp
  | expression ':=' expression #AssignExp
  | 'assert' '(' expression ')' #AssertExp 
  | '-' expression #NegExp
  | qualifiedName '~' #PrevExp
  | 'forall' rngBindingList SUCHTHAT expression #ForallExp 
  | 'exists' rngBindingList SUCHTHAT expression #ExistsExp 
  | pattern '->' expression #LambdaExp
  | 'continue' #ContinueExp
  | 'break' #BreakExp
  | 'return' expression? #ReturnExp
  | '$result' #ResultExp
  ;

match:
  'case' pattern ('|' pattern)* '=>' expression
  ;

argumentList: 
    positionalArgumentList #PosArgList
  | namedArgumentList # NamedArgList
  ;

positionalArgumentList:
    expression ((',' | (']' '[')) expression)* 
    ;

namedArgumentList:
   namedArgument (',' namedArgument)* 
  ;

namedArgument :
    Identifier '::' expression
  ;

collectionOrType:
    expression
  | type
  ;

rngBindingList:
    rngBinding (',' rngBinding)*
  ;

rngBinding:
    patternList ':' collectionOrType
  ;

patternList:
    pattern (',' pattern)*
  ;

pattern:
    literal # LiteralPattern
  | '_' #DontCarePattern   
  | Identifier #IdentPattern
  | '(' pattern (',' pattern)+ ')' #CartesianPattern  
  | pattern ':' type # TypedPattern
  ;
  
identifierList:
    Identifier (',' Identifier)*
  ;

expressionList:
    expression (',' expression)*
  ;
    
qualifiedName:
    Identifier ('.' Identifier)*
  ;

literal:
  DateLiteral
  | DurationLiteral
  | IntegerLiteral
  | RealLiteral
  | CharacterLiteral
  | StringLiteral
  | BooleanLiteral
  | NullLiteral
  | ThisLiteral
  ;

SUCHTHAT :
    ':-' 
  ;

DateLiteral:
      Year '-' Day ('T' [0-2] [0-9] ':' [0-5] [0-9] ':' [0-5] [0-9] ('.' [0-9] [0-9] [0-9])? Timezone?)?
    ;

fragment
SimpleDateLiteral:
      Year '-' Day ('T' [0-2] [0-9] ':' [0-5] [0-9] ':' [0-5] [0-9])?
    ;

fragment
Year:
      [0-9] [0-9] ([0-9] [0-9])?
    ;

fragment
Day:
      [0-3] [0-9] [0-9]
    | Month '-' [0-3]? [0-9]
    ;

fragment
Timezone:
      ('+'|'-') [0-2]? [0-9] ':' '00'
    | [zZ]
    | [A-Za-z] [A-Za-z] [A-Za-z]
    ;

fragment
Month:
    [0-1]? [0-9]
    | JAN | FEB | MAR | APR | MAY | JUN | JUL | AUG | SEPT | OCT | NOV | DEC
    ;

fragment
JAN : [Jj][Aa][Nn] ;
fragment
FEB : [Ff][Ee][Bb] ;
fragment
MAR : [Mm][Aa][Rr] ;
fragment
APR : [Aa][Pp][Rr] ;
fragment
MAY : [Mm][Aa][Yy] ;
fragment
JUN : [Jj][Uu][Nn] ;
fragment
JUL : [Jj][Uu][Ll] ;
fragment
AUG : [Aa][Uu][Gg] ;
fragment
SEPT : [Ss][Ee][Pp] ;
fragment
OCT : [Oo][Cc][Tt] ;
fragment
NOV : [Nn][Oo][Vv] ;
fragment
DEC : [Dd][Ee][Cc] ;

DurationLiteral:
      'P' [0-9]+ 'Y' ([0-9]+ 'M')? ([0-9]+ 'W')? ([0-9]+ 'D')? TDur?
    | 'P' [0-9]+ 'M' ([0-9]+ 'W')? ([0-9]+ 'D')? TDur?
    | 'P' [0-9]+ 'W' ([0-9]+ 'D')? TDur?
    | 'P' [0-9]+ 'D' TDur?
    | 'P' TDur
    | 'P' SimpleDateLiteral
    ;

fragment
TDur:
      'T' [0-9]+ 'H' ([0-9]+ 'M')? ([0-9]+ 'S')?
    | 'T' [0-9]+ 'M' ([0-9]+ 'S')?
    | 'T' [0-9]+ 'S'
    ;

IntegerLiteral:
      DecimalIntegerLiteral
    | HexIntegerLiteral
    | OctalIntegerLiteral
    | BinaryIntegerLiteral
    ;

fragment
DecimalIntegerLiteral:
      DecimalNumeral IntegerTypeSuffix?
    ;

fragment
HexIntegerLiteral:
      HexNumeral IntegerTypeSuffix?
    ;

fragment
OctalIntegerLiteral:
      OctalNumeral IntegerTypeSuffix?
    ;

fragment
BinaryIntegerLiteral:
      BinaryNumeral IntegerTypeSuffix?
    ;

fragment
IntegerTypeSuffix:
      [lL]
    ;

fragment
DecimalNumeral:
      '0'
    |   NonZeroDigit (Digits? | Underscores Digits)
    ;

fragment
Digits:
      Digit (DigitOrUnderscore* Digit)?
    ;

fragment
Digit:
      '0'
    |   NonZeroDigit
    ;

fragment
NonZeroDigit:
      [1-9]
    ;

fragment
DigitOrUnderscore:
      Digit
    |   '_'
    ;

fragment
Underscores:
      '_'+
    ;

fragment
HexNumeral:
      '0' [xX] HexDigits
    ;

fragment
HexDigits:
      HexDigit (HexDigitOrUnderscore* HexDigit)?
    ;

fragment
HexDigit:
      [0-9a-fA-F]
    ;

fragment
HexDigitOrUnderscore:
      HexDigit
    |   '_'
    ;

fragment
OctalNumeral:
      '0' Underscores? OctalDigits
    ;

fragment
OctalDigits:
      OctalDigit (OctalDigitOrUnderscore* OctalDigit)?
    ;

fragment
OctalDigit:
      [0-7]
    ;

fragment
OctalDigitOrUnderscore:
      OctalDigit
    |   '_'
    ;

fragment
BinaryNumeral:
      '0' [bB] BinaryDigits
    ;

fragment
BinaryDigits:
      BinaryDigit (BinaryDigitOrUnderscore* BinaryDigit)?
    ;

fragment
BinaryDigit:
      [01]
    ;

fragment
BinaryDigitOrUnderscore:
      BinaryDigit
    |   '_'
    ;

RealLiteral:
      DecimalFloatingPointLiteral
    |   HexadecimalFloatingPointLiteral
    ;

fragment
DecimalFloatingPointLiteral:
      Digits '.' Digits? ExponentPart? FloatTypeSuffix?
    |   '.' Digits ExponentPart? FloatTypeSuffix?
    |   Digits ExponentPart FloatTypeSuffix?
    |   Digits FloatTypeSuffix
    ;

fragment
ExponentPart:
      ExponentIndicator SignedInteger
    ;

fragment
ExponentIndicator:
      [eE]
    ;

fragment
SignedInteger:
      Sign? Digits
    ;

fragment
Sign:
      [+-]
    ;

fragment
FloatTypeSuffix:
      [fFdD]
    ;

fragment
HexadecimalFloatingPointLiteral:
      HexSignificand BinaryExponent FloatTypeSuffix?
    ;

fragment
HexSignificand:
      HexNumeral '.'?
    |   '0' [xX] HexDigits? '.' HexDigits
    ;

fragment
BinaryExponent:
      BinaryExponentIndicator SignedInteger
    ;

fragment
BinaryExponentIndicator:
      [pP]
    ;

BooleanLiteral:
      'true'
    |   'false'
    ;

NullLiteral:
  'null'
  ;

ThisLiteral:
  'this'
  ;

CharacterLiteral:
      '\'' SingleCharacter '\''
    |   '\'' EscapeSequence '\''
    ;

fragment
SingleCharacter:
      ~['\\]
    ;
    
StringLiteral:
      '"' StringCharacters? '"'
    ;

fragment
StringCharacters:
      StringCharacter+
    ;

fragment
StringCharacter:
      ~["\\]
    |   EscapeSequence
    ;

fragment
EscapeSequence:
      '\\' [btnfr"'\\]
    |   OctalEscape
    |   UnicodeEscape
    ;

fragment
OctalEscape:
      '\\' OctalDigit
    |   '\\' OctalDigit OctalDigit
    |   '\\' ZeroToThree OctalDigit OctalDigit
    ;

fragment
UnicodeEscape:
      '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

fragment
ZeroToThree:
      [0-3]
    ;

Identifier:
      JavaLetter JavaLetterOrDigit*
    ;

fragment
JavaLetter:
      [a-zA-Z$_] // these are the "java letters" below 0xFF
    |   // covers all characters above 0xFF which are not a surrogate
        ~[\u0000-\u00FF\uD800-\uDBFF]
        {Character.isJavaIdentifierStart(_input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierStart(Character.toCodePoint((char)_input.LA(-2), (char)_input.LA(-1)))}?
    ;

fragment
JavaLetterOrDigit:
      [a-zA-Z0-9$_] // these are the "java letters or digits" below 0xFF
    |   // covers all characters above 0xFF which are not a surrogate
        ~[\u0000-\u00FF\uD800-\uDBFF]
        {Character.isJavaIdentifierPart(_input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierPart(Character.toCodePoint((char)_input.LA(-2), (char)_input.LA(-1)))}?
    ;

CommentBorder:
   '===' '='*
   ;

CBlockComment :
    '/*' .*? '*/' -> skip
  ;

BlockComment :
     CommentBorder .*? CommentBorder -> skip
  ;

CLineComment:
    '//' ~[\r\n]* -> skip
  ;

LineComment:
    '--' ~[\r\n]* -> skip
  ;

WS:
    [ \t\r\n\u000C]+ -> skip
  ;

SEP:
  ';' 
;
