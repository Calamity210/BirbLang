---
id: walkthrough
title: Walkthrough
sidebar_label: Walkthrough
---

This document should give you a quick overview to get you started on contributing to birb.

## ASTNode 

An AST or abstract syntax tree is an approximate representation of a program as a tree. Each node denotes an idea within the program.
The ASTNode is an abstract class implemented by the subclasses such as `VariableNode` or `StringNode`.

Consider the following:
```birb
String greetings = 'Henlo!';
```

This would look something like:
```
├── VarDefNode
    └── lineNum
            └── '1'
    └── isClassChild
            └── false
    └── isFinal
            └── false
    └── isNullable
            └── false // Null-safety still being worked on
    └── type // We are removing this for all ASTNodes
            └── ASTType.AST_VARIABLE_DEFINITION
    └── variableName
            └── 'greetings'
    └── variableValue
            └── StringNode
                    └── type
                            └── ASTType.AST_STRING
                    └── stringValue
                            └── 'Henlo!'
    └── variableType
            └── TypeNode
                    └── typeValue
                            └── DATA_TYPE_STRING
```

## What exactly happens when you run a program?

When a program runs,the contents of the file get passed to the lexer (tokenizer). The lexer `lexes` the program into tokens and passes them to the parser.

The parser walks through those tokens and parses them into an ASTNode (see (ASTNode)[#ASTNode]). With the AST, the runtime can now apply its magic and actually run the code.

## Lexer

In short, a lexer's job is to take a program as an input and output a sequence of tokens.

Let's take the following code as an example:
```birb
double i = 0.5;
```

The lexer would start at the beginning of the program at the character `d`, now when it encounters `d`, the lexer already knows it's an identifier, so it continuously advances to the next token as long as the current character is alphanumeric or `_`. Birb identifiers must follow the pattern ([A-Za-z_][A-Za-z0-9-]\??).
Once the lexer reaches the character `e` or any character not following the pattern mentioned, it knows that the token completed and returns an identifier token with the value of `double`. 

The lexer does the same for `i`, returns an equal token for `=` and then reaches a numeric character. It knows this is not an identifier as it doesn't start with an alphabetical character nor `_`.

Since the token is numeric, it begins collecting an int when it encounters `.`. The "dot" is an obvious indicator that the current token is a double, it continues collecting the double until the `;` and then returns a double token
with the value of `0.5`. At last, it returns a semi-colon token.

```
type = TOKEN_ID, value = 'double'
type = TOKEN_ID, value = 'i'
type = TOKEN_EQUAL, value = '='
type = TOKEN_DOUBLE_VALUE, value = '0.5'
type = TOKEN_SEMI, value = ';'
```

## Parser
The parser takes tokens from the lexer and "parses" them into `ASTNodes`. 

Following with the Lexer example, the parser would first get a `TOKEN_ID`. The parser checks its value and realizes it's
a datatype(`double`). It moves to the next token and finds another `TOKEN_ID`. At this point the parser knows that this is probably leading to either 
a variable definition or function definition. If the next token is a `TOKEN_LPAREN (`, the parser starts parsing a function definition.

In our case the next token is `TOKEN_EQUAL`, the parser now knows it is parsing a variable definition and so it creates a
`VarDefNode`. It checks the datatype encountered and gives the `VarDefNode.variableType` accordingly, it moves on and 
sets the variables value to a `DoubleNode` with a `DoubleNode.doubleVal` of `0.5`.

## Runtime
The runtime takes the `ASTNodes` passed by the parser and uses them to actually make the program work, for the example used for
the parser and lexer, it would simply take the variable definition and save it in the local scope. 
