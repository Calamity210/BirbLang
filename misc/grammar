Grammar
===

program -> ^statements

oneStatementCompound -> statement ";"

statement -> 
        $modifier definition | definition | while | for
        | if | switch | bool | null | return | break
        | continue | iterate | assert
        | IDENTIFIER variable (funcCall)* ("." expression)* ("[" expression "]")*
    *case NUMBER|STRING|DOUBLE|INT
        | expression
    *case ++|--|**
        | $operator statement
    *case "{"
        | "{" .* "}"
    *case "["
        | "[" .* "]" ";"
        | $noop
$modifier -> "const" | "final" | "static"
$operator -> "++" | "--" | "**"
$noop ->!

statements -> statement (";"? statement)*
%expressed% -> statement@stmt (";"?[@stmt!=NOOP&&prev="}"] statement)*

type -> "void" | "String" | "StrBuffer" | "var" | "int"
        | "double" | "bool" | "class" | "enum"
        | "List" | "Map" | "Source"
%expressed% -> IDENTIFIER

variable -> expression[start="}"]
        | "=" expression
        | $doubleCharOp
        | $opEqualOp expression
        | #empty <- consumes nothing
$doubleCharOp -> "++" | "--" | "**"
$opEqualOp -> "+=" | "-=" | "*=" | "/=" | "%="

class -> map[prev!=TOKEN_ID]
    | "{" definition? (";"? definition?)* "}"

enum -> "{" (IDENTIFIER variable ("," IDENTIFIER variable))? "}"

map -> "{" ($keyValue ("," $keyValue)*)? "}"
$keyValue -> STRING ":" expression

list -> "[" (expression ("," expression)*)? "]"

factor -> ($unaryOp term) // is in while loop but has a return statement so only accept one
        | bool | null
        | $doubleCharOp variable[binaryOpRight] ("." factor)? ("[" expression "]")* funcCall*
        | IDENTIFIER variable ("." factor)? ("[" expression "]")* funcCall*
        | "(" expression ")"
        | int | double | string | class | list
%expressed% -> dead code in doubleCharOp
$unaryOp -> "+" | "-" | "++" | "--" | "!"
$doubleCharOp -> "++" | "--" | "**"

term -> $modifier definition
        | definition
        | factor (funcCall)? ($biOp factor)*
$modifier -> "const" | "final" | "static"
$biOp -> "/" | "*" | "<" | ">" | "==" | "!="

expression -> term ($operator term)* ("and" term)* ternary?
$operator -> "+" | "-" | "++" | "--"

if -> "if" "(" expression ")" ("{" statements "}" | oneStatementCompound)

switch -> "switch" "(" expression ")" 
    "{" IDENTIFIER statement ":" "{" statements "}" 
    ("case" statement ":" "{" statements "}")*
    IDENTIFIER ":" "{" statements "}" "}"

ternary -> "?" term ":" term

iterate -> IDENTIFIER expression IDENTIFIER (($modifier definition) | ($dataType definition) | (IDENTIFIER variable)) 
$modifier -> "const" | "final" | "static"

assert -> "assert" expression

while -> "while" "(" expression ")"
    ("{" statements "}" | oneStatementCompound)

for -> "for" "(" statement ";" expression ";" statement ")"
    ("{" statements "}" | oneStatementCompound)

funcCall -> "(" $funcCallArgs? ")"
$funcCallArgs -> expression ("," expression)*

definition -> type["StrBuffer"] stringBuffer
    | type["enum"] (funcDef | variableDef)
    | type (funcDef | variableDef)

variableDef -> (enum IDENTIFIER)? expression? ("=" expression)?

funcDef -> "(" (expression ("," expression)*)? ")" 
    ($rBraceRule | $equalRule | "{" statements "}")

$rBraceRule -> variable ("," $defOrIdVar)* ("," $modifier IDENTIFIER)?
%expressed% -> dead code in first two conditions, RBRACE token is never consumed.

$equalRule -> "=" $modifier definition
$equalRule -> "=" ($defOrIdVar) ("," ($defOrIdVar))* ("," $modifier definition)?

$defOrIdVar -> definition | IDENTIFIER variable

stringBuffer -> "(" STRING ")"

double -> DOUBLE

string -> STRING

int -> INTEGER

bool -> "false" | "true"

null -> "null"

break -> "break"

continue -> "continue"

return -> "return" expression
