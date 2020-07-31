import 'dart:io';

import 'AST.dart';
import 'data_type.dart';
import 'lexer.dart';
import 'scope.dart';
import 'token.dart';

const String WHILE = 'while';
const String FOR = 'for';
const String IF = 'if';
const String ELSE = 'else';
const String RETURN = 'return';
const String BREAK = 'break';
const String CONTINUE = 'continue';
const String NEW = 'new';
const String ITERATE = 'iterate';
const String ASSERT = 'assert';
const String NULL = 'null';
const String TRUE = 'true';
const String FALSE = 'false';

class Parser {
  Lexer lexer;
  Token prevToken;
  Token curToken;
  DataType dataType;
}

/// Initializes and returns a parser with a lexer
Parser initParser(Lexer lexer) {
  var parser = Parser()..lexer = lexer;
  parser.curToken = getNextToken(parser.lexer);

  return parser;
}

/// Throws an error and exits
void parserTypeError(Parser parser) {
  print('[Line ${parser.lexer.lineNum}] Invalid type');
  exit(1);
}

/// Throws an error and exits
void parserSyntaxError(Parser parser) {
  print('[Line ${parser.lexer.lineNum}] Syntax error');
  exit(1);
}

/// Throws an error and exits
void parserUnexpectedToken(Parser parser, TokenType type) {
  print(
      '[Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, was expecting `$type`');
  exit(1);
}

/// Sets the ast to be a child of a class
AST asClassChild(AST ast, AST object) {
  ast.isClassChild = true;
  ast.parent = object;
  return ast;
}

/// Check if the token is a DataType
bool isDataType(String tokenValue) {
  return (tokenValue == 'Future' ||
      tokenValue == 'void' ||
      tokenValue == 'var' ||
      tokenValue == 'int' ||
      tokenValue == 'String' ||
      tokenValue == 'double' ||
      tokenValue == 'bool' ||
      tokenValue == 'class' ||
      tokenValue == 'enum' ||
      tokenValue == 'List' ||
      tokenValue == 'Map' ||
      tokenValue == 'Source');
}

AST parseOneStatementCompound(Parser parser, Scope scope) {
  var compound = initASTWithLine(ASTType.AST_COMPOUND, parser.lexer.lineNum);
  compound.scope = scope;

  var statement = parseStatement(parser, scope);
  eat(parser, TokenType.TOKEN_SEMI);
  compound.compoundValue.add(statement);

  return compound;
}

AST parse(Parser parser, {Scope scope}) {
  return parseStatements(parser, scope);
}

void eat(Parser parser, TokenType type) {
  if (parser.curToken.type != type) {
    parserUnexpectedToken(parser, type);
  } else {
    parser.prevToken = parser.curToken;
    parser.curToken = getNextToken(parser.lexer);
  }
}

AST parseStatement(Parser parser, Scope scope) {
  switch (parser.curToken.type) {
    case TokenType.TOKEN_ID:
      {
        var tokenValue = parser.curToken.value;

        if (isDataType(tokenValue)) {
          return parseFuncDef(parser, scope);
        }
        switch (tokenValue) {
          case WHILE:
            return parseWhile(parser, scope);
          case FOR:
            return parseFor(parser, scope);
          case IF:
            return parseIf(parser, scope);
          case FALSE:
          case TRUE:
            return parseBool(parser, scope);
          case NULL:
            return parseNull(parser, scope);
          case RETURN:
            return parseReturn(parser, scope);
          case BREAK:
            return parseBreak(parser, scope);
          case CONTINUE:
            return parseContinue(parser, scope);
          case NEW:
            return parseNew(parser, scope);
          case ITERATE:
            return parseIterate(parser, scope);
          case ASSERT:
            return parseAssert(parser, scope);
        }

        eat(parser, TokenType.TOKEN_ID);

        var a = parseVariable(parser, scope);

        while (parser.curToken.type == TokenType.TOKEN_LPAREN) {
          a = parseFuncCall(parser, scope, a);
        }

        while (parser.curToken.type == TokenType.TOKEN_DOT) {
          eat(parser, TokenType.TOKEN_DOT);

          var ast = initASTWithLine(
              ASTType.AST_ATTRIBUTE_ACCESS, parser.lexer.lineNum);
          ast.binaryOpLeft = a;
          ast.binaryOpRight = parseExpression(parser, scope);

          a = ast;
        }

        while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
          var astListAccess =
              initASTWithLine(ASTType.AST_LIST_ACCESS, parser.lexer.lineNum);
          astListAccess.binaryOpLeft = a;
          eat(parser, TokenType.TOKEN_LBRACKET);
          astListAccess.listAccessPointer = parseExpression(parser, scope);
          eat(parser, TokenType.TOKEN_RBRACKET);

          a = astListAccess;
        }

        if (a != null) return a;
      }
      break;
    case TokenType.TOKEN_NUMBER_VALUE:
    case TokenType.TOKEN_STRING_VALUE:
    case TokenType.TOKEN_DOUBLE_VALUE:
    case TokenType.TOKEN_INT_VALUE:
      return parseExpression(parser, scope);
    case TokenType.TOKEN_PLUS_PLUS:
    case TokenType.TOKEN_SUB_SUB:
    case TokenType.TOKEN_MUL_MUL:
      {
        Token operator = parser.curToken;
        eat(parser, operator.type);

        AST astVarMod =
            initASTWithLine(ASTType.AST_VARIABLE_MODIFIER, parser.lexer.lineNum)
              ..binaryOpRight = parseStatement(parser, scope)
              ..binaryOperator = operator
              ..scope = scope;

        return astVarMod;
      }
      break;
    case TokenType.TOKEN_ANON_ID:
      {
        print(
            '[Line ${parser.lexer.lineNum}] Expected token `${parser.curToken.value}`');
        exit(1);
      }
      break;

    default:
      return initASTWithLine(ASTType.AST_NOOP, parser.lexer.lineNum);
  }

  return initASTWithLine(ASTType.AST_NOOP, parser.lexer.lineNum);
}

AST parseStatements(Parser parser, Scope scope) {
  var compound = initASTWithLine(ASTType.AST_COMPOUND, parser.lexer.lineNum);
  compound.scope = scope;

  var statement = parseStatement(parser, scope);

  compound.compoundValue.add(statement);

  while (parser.curToken.type == TokenType.TOKEN_SEMI ||
      statement.type != ASTType.AST_NOOP) {
    if (parser.curToken.type == TokenType.TOKEN_SEMI) {
      eat(parser, TokenType.TOKEN_SEMI);
    }

    statement = parseStatement(parser, scope);

    compound.compoundValue.add(statement);
  }

  return compound;
}

AST parseType(Parser parser, Scope scope) {
  var astType = initASTWithLine(ASTType.AST_TYPE, parser.lexer.lineNum);
  astType.scope = scope;

  var type = initDataType();

  var tokenValue = parser.curToken.value;

  switch (tokenValue) {
    case 'void':
      type.type = DATATYPE.DATA_TYPE_VOID;
      break;
    case 'String':
      type.type = DATATYPE.DATA_TYPE_STRING;
      break;
    case 'var':
      type.type = DATATYPE.DATA_TYPE_VAR;
      break;
    case 'int':
      type.type = DATATYPE.DATA_TYPE_INT;
      break;
    case 'double':
      type.type = DATATYPE.DATA_TYPE_DOUBLE;
      break;
    case 'bool':
      type.type = DATATYPE.DATA_TYPE_BOOL;
      break;
    case 'class':
      type.type = DATATYPE.DATA_TYPE_CLASS;
      break;
    case 'enum':
      type.type = DATATYPE.DATA_TYPE_ENUM;
      break;
    case 'List':
      type.type = DATATYPE.DATA_TYPE_LIST;
      break;
    case 'Map':
      type.type = DATATYPE.DATA_TYPE_MAP;
      break;
    case 'Source':
      type.type = DATATYPE.DATA_TYPE_SOURCE;
      break;
  }

  astType.typeValue = type;

  eat(parser, TokenType.TOKEN_ID);

  return astType;
}

AST parseDouble(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_DOUBLE, parser.lexer.lineNum);
  ast.scope = scope;
  ast.doubleValue = double.parse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_DOUBLE_VALUE);

  return ast;
}

AST parseString(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_STRING, parser.lexer.lineNum)
    ..scope = scope
    ..stringValue = parser.curToken.value;

  eat(parser, TokenType.TOKEN_STRING_VALUE);

  return ast;
}

AST parseInt(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_INT, parser.lexer.lineNum)
    ..scope = scope
    ..stringValue = parser.curToken.value
    ..intVal = int.parse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_INT_VALUE);

  return ast;
}

AST parseBool(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_BOOL, parser.lexer.lineNum)
    ..scope = scope;

  if (parser.curToken.value == 'false' || parser.curToken.value == 'true') {
    ast.boolValue = parser.curToken.value == 'true';
  } else {
    print('Expected a boolean value, but got ${parser.curToken.value}');
  }

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

AST parseNull(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_NULL, parser.lexer.lineNum)
    ..scope = scope;

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

AST parseVariable(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_VARIABLE, parser.lexer.lineNum)
    ..scope = scope
    ..variableName = parser.prevToken.value;

  if (parser.curToken.type == TokenType.TOKEN_RBRACE) {
    var astAssign =
        initASTWithLine(ASTType.AST_VARIABLE_ASSIGNMENT, parser.lexer.lineNum)
          ..variableAssignmentLeft = ast
          ..variableValue = parseExpression(parser, scope)
          ..scope = scope;

    return astAssign;
  }

  if (parser.curToken.type == TokenType.TOKEN_EQUAL) {
    eat(parser, TokenType.TOKEN_EQUAL);
    var astAssign =
        initASTWithLine(ASTType.AST_VARIABLE_ASSIGNMENT, parser.lexer.lineNum);
    astAssign.variableAssignmentLeft = ast;
    ast.variableValue = parseExpression(parser, scope);
    astAssign.scope = scope;

    return astAssign;
  }
  if (parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_MUL_MUL) {
    Token operator = parser.curToken;

    eat(parser, operator.type);

    AST astVarMod =
        initASTWithLine(ASTType.AST_VARIABLE_MODIFIER, parser.lexer.lineNum)
          ..binaryOpLeft = ast
          ..binaryOperator = operator
          ..scope = scope;

    return astVarMod;
  } else if (parser.curToken.type == TokenType.TOKEN_PLUS_EQUAL ||
      parser.curToken.type == TokenType.TOKEN_SUB_EQUAL ||
      parser.curToken.type == TokenType.TOKEN_MUL_EQUAL ||
      parser.curToken.type == TokenType.TOKEN_DIV_EQUAL ||
      parser.curToken.type == TokenType.TOKEN_MOD_EQUAL) {
    Token operator = parser.curToken;

    eat(parser, operator.type);

    AST astVarMod =
        initASTWithLine(ASTType.AST_VARIABLE_MODIFIER, parser.lexer.lineNum)
          ..binaryOpLeft = ast
          ..binaryOpRight = parseExpression(parser, scope)
          ..binaryOperator = operator
          ..scope = scope;

    return astVarMod;
  }

  return ast;
}

AST parseClass(Parser parser, Scope scope) {
  if (parser.prevToken.type != TokenType.TOKEN_ID)
    return parseMap(parser, scope);

  AST ast = initASTWithLine(ASTType.AST_CLASS, parser.lexer.lineNum);

  ast.scope = scope;
  ast.classChildren = [];

  var newScope = initScope(false);

  if (scope != null) {
    if (scope.owner != null) {
      newScope.owner = scope.owner;
    }
  }

  eat(parser, TokenType.TOKEN_LBRACE);

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_ID) {
      ast.classChildren.add(asClassChild(parseFuncDef(parser, newScope), ast));
    }

    while (parser.curToken.type == TokenType.TOKEN_SEMI) {
      eat(parser, TokenType.TOKEN_SEMI);

      if (parser.curToken.type == TokenType.TOKEN_ID) {
        ast.classChildren
            .add(asClassChild(parseFuncDef(parser, newScope), ast));
      }
    }
  }

  eat(parser, TokenType.TOKEN_RBRACE);

  return ast;
}

AST parseEnum(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_ENUM, parser.lexer.lineNum);
  ast.scope = scope;
  ast.enumChildren = [];

  var newScope = initScope(false);

  if (scope != null) {
    if (scope.owner != null) {
      newScope.owner = scope.owner;
    }
  }

  eat(parser, TokenType.TOKEN_LBRACE);

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_ID) {
      eat(parser, TokenType.TOKEN_ID);
      ast.enumChildren.add(parseVariable(parser, newScope));
    }

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);

      if (parser.curToken.type == TokenType.TOKEN_ID) {
        eat(parser, TokenType.TOKEN_ID);
        ast.enumChildren.add(parseVariable(parser, newScope));
      }
    }
  }

  eat(parser, TokenType.TOKEN_RBRACE);

  return ast;
}

AST parseMap(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_LBRACE);

  var ast = initASTWithLine(ASTType.AST_MAP, parser.lexer.lineNum);
  ast.scope = scope;
  ast.map = {};

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_STRING_VALUE) {
      String key = parser.curToken.value;
      eat(parser, TokenType.TOKEN_STRING_VALUE);

      if (parser.curToken.type == TokenType.TOKEN_COLON)
        eat(parser, TokenType.TOKEN_COLON);
      else {
        print(
            'Error: [Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, expected `:`.');
        exit(1);
      }

      if (parser.curToken.type == TokenType.TOKEN_COMMA) {
        print(
            'Error: [Line ${parser.lexer.lineNum}] Expected value for key `$key`');
        exit(1);
      }
      ast.map[key] = parseExpression(parser, scope);
    } else {
      print(
          'Error: [Line ${parser.lexer.lineNum}] Maps can only hold strings as keys.');
      exit(1);
    }
  }

  while (parser.curToken.type == TokenType.TOKEN_COMMA) {
    eat(parser, TokenType.TOKEN_COMMA);

    String key = parser.curToken.value;
    eat(parser, TokenType.TOKEN_STRING_VALUE);

    if (parser.curToken.type == TokenType.TOKEN_COLON)
      eat(parser, TokenType.TOKEN_COLON);
    else {
      print(
          'Error: [Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, expected `:`.');
      exit(1);
    }

    if (parser.curToken.type == TokenType.TOKEN_COMMA) {
      print(
          'Error: [Line ${parser.lexer.lineNum}] Expected value for key `$key`');
      exit(1);
    }
    ast.map[key] = parseExpression(parser, scope);
  }

  eat(parser, TokenType.TOKEN_RBRACE);
  return ast;
}

AST parseList(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_LBRACKET);
  var ast = initASTWithLine(ASTType.AST_LIST, parser.lexer.lineNum);
  ast.scope = scope;
  ast.listChildren = [];

  if (parser.curToken.type != TokenType.TOKEN_RBRACKET) {
    ast.listChildren.add(parseExpression(parser, scope));
  }

  while (parser.curToken.type == TokenType.TOKEN_COMMA) {
    eat(parser, TokenType.TOKEN_COMMA);
    ast.listChildren.add(parseExpression(parser, scope));
  }

  eat(parser, TokenType.TOKEN_RBRACKET);
  return ast;
}

AST parseFactor(Parser parser, Scope scope, bool isMap) {
  while (parser.curToken.type == TokenType.TOKEN_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB ||
      parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB) {
    var unOpOperator = parser.curToken;
    eat(parser, unOpOperator.type);

    var ast = initASTWithLine(ASTType.AST_UNARYOP, parser.lexer.lineNum);
    ast.scope = scope;
    ast.unaryOperator = unOpOperator;
    ast.unaryOpRight = parseTerm(parser, scope);

    return ast;
  }

  switch (parser.curToken.value) {
    case TRUE:
    case FALSE:
      return parseBool(parser, scope);
    case NULL:
      return parseNull(parser, scope);
    case NEW:
      return parseNew(parser, scope);
  }

  if (parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_MUL_MUL) {
    eat(parser, parser.curToken.type);

    var a = parseVariable(parser, scope).binaryOpRight;

    if (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast =
          initASTWithLine(ASTType.AST_ATTRIBUTE_ACCESS, parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      ast.binaryOpRight = parseFactor(parser, scope, false);

      a = ast;
    }

    while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
      var astListAccess =
          initASTWithLine(ASTType.AST_LIST_ACCESS, parser.lexer.lineNum);
      astListAccess.binaryOpLeft = a;

      eat(parser, TokenType.TOKEN_LBRACKET);
      astListAccess.listAccessPointer = parseExpression(parser, scope);
      eat(parser, TokenType.TOKEN_RBRACKET);

      a = astListAccess;
    }

    while (parser.curToken.type == TokenType.TOKEN_LPAREN)
      a = parseFuncCall(parser, scope, a);

    if (a != null) return a;
  }

  if (parser.curToken.type == TokenType.TOKEN_ID) {
    eat(parser, parser.curToken.type);

    var a = parseVariable(parser, scope);

    if (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast =
          initASTWithLine(ASTType.AST_ATTRIBUTE_ACCESS, parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      ast.binaryOpRight = parseFactor(parser, scope, false);

      a = ast;
    }

    while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
      var astListAccess =
          initASTWithLine(ASTType.AST_LIST_ACCESS, parser.lexer.lineNum);
      astListAccess.binaryOpLeft = a;

      eat(parser, TokenType.TOKEN_LBRACKET);
      astListAccess.listAccessPointer = parseExpression(parser, scope);
      eat(parser, TokenType.TOKEN_RBRACKET);

      a = astListAccess;
    }

    while (parser.curToken.type == TokenType.TOKEN_LPAREN)
      a = parseFuncCall(parser, scope, a);

    if (a != null) return a;
  }

  /* */
  if (parser.curToken.type == TokenType.TOKEN_LPAREN) {
    eat(parser, TokenType.TOKEN_LPAREN);
    var astExpression = parseExpression(parser, scope);
    eat(parser, TokenType.TOKEN_RPAREN);

    return astExpression;
  }

  switch (parser.curToken.type) {
    case TokenType.TOKEN_NUMBER_VALUE:
    case TokenType.TOKEN_INT_VALUE:
      return parseInt(parser, scope);
    case TokenType.TOKEN_DOUBLE_VALUE:
      return parseDouble(parser, scope);
    case TokenType.TOKEN_STRING_VALUE:
      return parseString(parser, scope);
    case TokenType.TOKEN_LBRACE:
      return parseClass(parser, scope);
    case TokenType.TOKEN_LBRACKET:
      return parseList(parser, scope);
    default:
      print('Unexpected ${parser.curToken.value}');
      exit(1);
      break;
  }
}

AST parseTerm(Parser parser, Scope scope) {
  var tokenValue = parser.curToken.value;

  if (isDataType(tokenValue)) {
    return parseFuncDef(parser, scope);
  }

  var node = parseFactor(parser, scope, false);
  AST astBinaryOp;

  if (parser.curToken.type == TokenType.TOKEN_LPAREN)
    node = parseFuncCall(parser, scope, node);

  while (parser.curToken.type == TokenType.TOKEN_DIV ||
      parser.curToken.type == TokenType.TOKEN_MUL ||
      parser.curToken.type == TokenType.TOKEN_LESS_THAN ||
      parser.curToken.type == TokenType.TOKEN_GREATER_THAN ||
      parser.curToken.type == TokenType.TOKEN_EQUALITY ||
      parser.curToken.type == TokenType.TOKEN_NOT_EQUAL) {
    var binaryOpOperator = parser.curToken;
    eat(parser, binaryOpOperator.type);

    astBinaryOp = initASTWithLine(ASTType.AST_BINARYOP, parser.lexer.lineNum);

    astBinaryOp.binaryOpLeft = node;
    astBinaryOp.binaryOperator = binaryOpOperator;
    astBinaryOp.binaryOpRight = parseFactor(parser, scope, false);

    node = astBinaryOp;
  }
  return node;
}

AST parseExpression(Parser parser, Scope scope) {
  var node = parseTerm(parser, scope);
  AST astBinaryOp;

  while (parser.curToken.type == TokenType.TOKEN_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB ||
      parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB) {
    if (parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        parser.curToken.type == TokenType.TOKEN_SUB_SUB) {
      var binaryOp = parser.curToken;
      eat(parser, binaryOp.type);

      astBinaryOp = initASTWithLine(ASTType.AST_BINARYOP, parser.lexer.lineNum);
      astBinaryOp.scope = scope;

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOp;
      astBinaryOp.binaryOpRight = parseTerm(parser, scope);

      node = astBinaryOp;
    } else {
      var binaryOp = parser.curToken;
      eat(parser, binaryOp.type);

      astBinaryOp = initASTWithLine(ASTType.AST_BINARYOP, parser.lexer.lineNum);
      astBinaryOp.scope = scope;

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOp;
      astBinaryOp.binaryOpRight = parseTerm(parser, scope);

      node = astBinaryOp;
    }
  }

  while (parser.curToken.type == TokenType.TOKEN_AND) {
    var binaryOp = parser.curToken;
    eat(parser, binaryOp.type);

    astBinaryOp = initASTWithLine(ASTType.AST_BINARYOP, parser.lexer.lineNum);
    astBinaryOp.scope = scope;

    astBinaryOp.binaryOpLeft = node;
    astBinaryOp.binaryOperator = binaryOp;
    astBinaryOp.binaryOpRight = parseTerm(parser, scope);

    node = astBinaryOp;
  }

  if (parser.curToken.type == TokenType.TOKEN_QUESTION)
    return parseTernary(parser, scope, node);

  return node;
}

AST parseBreak(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  return initASTWithLine(ASTType.AST_BREAK, parser.lexer.lineNum);
}

AST parseContinue(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  return initASTWithLine(ASTType.AST_CONTINUE, parser.lexer.lineNum);
}

AST parseReturn(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ASTType.AST_RETURN, parser.lexer.lineNum);
  ast.scope = scope;

  if (parser.curToken.type != TokenType.TOKEN_SEMI) {
    ast = parseExpression(parser, scope);
  }

  return ast;
}

AST parseIf(Parser parser, Scope scope) {
  var ast = initASTWithLine(ASTType.AST_IF, parser.lexer.lineNum);
  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);

  ast.ifExpression = parseExpression(parser, scope);

  eat(parser, TokenType.TOKEN_RPAREN);

  ast.scope = scope;

  if (parser.curToken.type == TokenType.TOKEN_LBRACE) {
    eat(parser, TokenType.TOKEN_LBRACE);
    ast.ifBody = parseStatements(parser, scope);
    eat(parser, TokenType.TOKEN_RBRACE);
  } else {
    ast.ifBody = parseOneStatementCompound(parser, scope);
  }

  if (parser.curToken.value == ELSE) {
    eat(parser, TokenType.TOKEN_ID);

    if (parser.curToken.value == IF) {
      ast.ifElse = parseIf(parser, scope);
      ast.ifElse.scope = scope;
    } else {
      if (parser.curToken.type == TokenType.TOKEN_LBRACE) {
        eat(parser, TokenType.TOKEN_LBRACE);
        ast.elseBody = parseStatements(parser, scope);
        ast.elseBody.scope = scope;
        eat(parser, TokenType.TOKEN_RBRACE);
      } else {
        var compound =
            initASTWithLine(ASTType.AST_COMPOUND, parser.lexer.lineNum);
        compound.scope = scope;
        var statement = parseStatement(parser, scope);
        eat(parser, TokenType.TOKEN_SEMI);
        compound.compoundValue.add(statement);

        ast.elseBody = compound;
        ast.elseBody.scope = scope;
      }
    }
  }

  return ast;
}

AST parseTernary(Parser parser, Scope scope, AST expr) {
  var ternary = initASTWithLine(ASTType.AST_TERNARY, parser.lexer.lineNum);
  ternary.ternaryExpression = expr;

  eat(parser, TokenType.TOKEN_QUESTION);

  ternary.ternaryBody = parseTerm(parser, scope);

  eat(parser, TokenType.TOKEN_COLON);

  ternary.ternaryElseBody = parseTerm(parser, scope);

  return ternary;
}

AST parseNew(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ASTType.AST_NEW, parser.lexer.lineNum);
  ast.newValue = parseExpression(parser, scope);

  return ast;
}

AST parseIterate(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var astVar = parseExpression(parser, scope);
  eat(parser, TokenType.TOKEN_ID);

  AST astFuncName;

  if (isDataType(parser.curToken.value)) {
    astFuncName = parseFuncDef(parser, scope);
  } else {
    eat(parser, TokenType.TOKEN_ID);
    astFuncName = parseVariable(parser, scope);
  }

  var ast = initASTWithLine(ASTType.AST_ITERATE, parser.lexer.lineNum);
  ast.iterateIterable = astVar;
  ast.iterateFunction = astFuncName;

  return ast;
}

AST parseAssert(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ASTType.AST_ASSERT, parser.lexer.lineNum);
  ast.assertExpression = parseExpression(parser, scope);

  return ast;
}

AST parseWhile(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);
  var ast = initASTWithLine(ASTType.AST_WHILE, parser.lexer.lineNum);
  ast.whileExpression = parseExpression(parser, scope);
  eat(parser, TokenType.TOKEN_RPAREN);

  if (parser.curToken.type == TokenType.TOKEN_LBRACE) {
    eat(parser, TokenType.TOKEN_LBRACE);
    ast.whileBody = parseStatements(parser, scope);
    eat(parser, TokenType.TOKEN_RBRACE);
    ast.scope = scope;
  } else {
    ast.whileBody = parseOneStatementCompound(parser, scope);
    ast.whileBody.scope = scope;
  }

  return ast;
}

AST parseFor(Parser parser, Scope scope) {
  var ast = initAST(ASTType.AST_FOR);

  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);

  ast.forInitStatement = parseStatement(parser, scope);
  eat(parser, TokenType.TOKEN_SEMI);

  ast.forConditionStatement = parseExpression(parser, scope);
  eat(parser, TokenType.TOKEN_SEMI);

  ast.forChangeStatement = parseStatement(parser, scope);

  eat(parser, TokenType.TOKEN_RPAREN);

  if (parser.curToken.type == TokenType.TOKEN_LBRACE) {
    eat(parser, TokenType.TOKEN_LBRACE);
    ast.forBody = parseStatements(parser, scope);
    ast.forBody.scope = scope;
    eat(parser, TokenType.TOKEN_RBRACE);
  } else {
    ast.forBody = parseOneStatementCompound(parser, scope);
    ast.forBody.scope = scope;
  }

  return ast;
}

AST parseFuncCall(Parser parser, Scope scope, AST expr) {
  var ast = initASTWithLine(ASTType.AST_FUNC_CALL, parser.lexer.lineNum);
  ast.funcCallExpression = expr;
  eat(parser, TokenType.TOKEN_LPAREN);

  ast.scope = scope;

  if (parser.curToken.type != TokenType.TOKEN_RPAREN) {
    var astExpr = parseExpression(parser, scope);

    if (astExpr.type == ASTType.AST_FUNC_DEFINITION) {
      astExpr.scope = initScope(false);
    }

    ast.funcCallArgs.add(astExpr);

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);
      astExpr = parseExpression(parser, scope);

      if (astExpr.type == ASTType.AST_FUNC_DEFINITION) {
        astExpr.scope = initScope(false);
      }

      ast.funcCallArgs.add(astExpr);
    }
  }

  eat(parser, TokenType.TOKEN_RPAREN);

  return ast;
}

AST parseFuncDef(Parser parser, Scope scope) {
  var astType = parseType(parser, scope);

  parser.dataType = astType.typeValue;

  String funcName;
  var isEnum = false;

  if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM) {
    funcName = parser.curToken.value;

    if (parser.curToken.type == TokenType.TOKEN_ID) {
      eat(parser, TokenType.TOKEN_ID);
    } else {
      eat(parser, TokenType.TOKEN_ANON_ID);
    }
  } else {
    isEnum = true;
  }

  // Function Definition?, otherwise Variable definition
  if (parser.curToken.type == TokenType.TOKEN_LPAREN) {
    var ast = initASTWithLine(ASTType.AST_FUNC_DEFINITION, parser.lexer.lineNum)
      ..funcName = funcName
      ..funcDefType = astType
      ..funcDefArgs = [];

    var newScope = initScope(false)..owner = ast;

    eat(parser, TokenType.TOKEN_LPAREN);

    if (parser.curToken.type != TokenType.TOKEN_RPAREN) {
      ast.funcDefArgs.add(parseExpression(parser, scope));

      while (parser.curToken.type == TokenType.TOKEN_COMMA) {
        eat(parser, TokenType.TOKEN_COMMA);
        ast.funcDefArgs.add(parseExpression(parser, scope));
      }
    }

    eat(parser, TokenType.TOKEN_RPAREN);

    if (parser.curToken.type == TokenType.TOKEN_RBRACE) {
      AST childDef;

      if (isDataType(parser.curToken.value)) {
        childDef = parseFuncDef(parser, scope);
      } else {
        eat(parser, TokenType.TOKEN_ID);
        childDef = parseVariable(parser, scope);
      }

      childDef.scope = newScope;
      ast.compChildren.add(childDef);

      while (parser.curToken.type == TokenType.TOKEN_COMMA) {
        eat(parser, TokenType.TOKEN_COMMA);

        if (isDataType(parser.curToken.value)) {
          childDef = parseFuncDef(parser, scope);
        } else {
          eat(parser, TokenType.TOKEN_ID);
          childDef = parseVariable(parser, scope);
        }

        childDef.scope = newScope;
        ast.compChildren.add(childDef);
      }
      return ast;
    }

    if (parser.curToken.type == TokenType.TOKEN_EQUAL) {
      eat(parser, TokenType.TOKEN_EQUAL);

      AST childDef;

      if (isDataType(parser.curToken.value)) {
        childDef = parseFuncDef(parser, scope);
      } else {
        eat(parser, TokenType.TOKEN_ID);
        childDef = parseVariable(parser, scope);
      }

      childDef.scope = newScope;
      ast.compChildren.add(childDef);

      while (parser.curToken.type == TokenType.TOKEN_COMMA) {
        eat(parser, TokenType.TOKEN_COMMA);

        if (isDataType(parser.curToken.value)) {
          childDef = parseFuncDef(parser, scope);
        } else {
          eat(parser, TokenType.TOKEN_ID);
          childDef = parseVariable(parser, scope);
        }

        childDef.scope = newScope;
        ast.compChildren.add(childDef);
      }
      return ast;
    }
    eat(parser, TokenType.TOKEN_LBRACE);
    ast.funcDefBody = parseStatements(parser, newScope);
    ast.funcDefBody.scope = newScope;
    eat(parser, TokenType.TOKEN_RBRACE);

    return ast;
  } else {
    var astVarDef =
        initASTWithLine(ASTType.AST_VARIABLE_DEFINITION, parser.lexer.lineNum);
    astVarDef.scope = scope;
    astVarDef.variableName = funcName;
    astVarDef.variableType = astType;

    if (isEnum) {
      var astType = initASTWithLine(ASTType.AST_TYPE, parser.lexer.lineNum);
      astType.scope = scope;

      var type = initDataType();
      type.type = DATATYPE.DATA_TYPE_ENUM;
      astType.typeValue = type;

      astVarDef.variableType = astType;
      astVarDef.variableValue = parseEnum(parser, scope);
      astVarDef.variableName = parser.curToken.value;
      eat(parser, TokenType.TOKEN_ID);
    }

    if (parser.curToken.type == TokenType.TOKEN_LBRACE) {
      astVarDef.variableValue = parseExpression(parser, scope);

      switch (astVarDef.variableValue.type) {
        case ASTType.AST_CLASS:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_CLASS)
            parserTypeError(parser);
          break;
        case ASTType.AST_ENUM:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM)
            parserTypeError(parser);
          break;
        case ASTType.AST_STRING:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_STRING;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING)
            parserTypeError(parser);
          break;
        case ASTType.AST_INT:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_INT;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_INT)
            parserTypeError(parser);
          break;
        case ASTType.AST_DOUBLE:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_DOUBLE;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_DOUBLE)
            parserTypeError(parser);
          break;
        case ASTType.AST_BOOL:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_BOOL;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_BOOL)
            parserTypeError(parser);
          break;
        case ASTType.AST_LIST:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_LIST;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_LIST)
            parserTypeError(parser);
          break;
        case ASTType.AST_MAP:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_MAP;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_MAP)
            parserTypeError(parser);
          break;
        case ASTType.AST_COMPOUND:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_SOURCE)
            parserTypeError(parser);
          break;
        default:
          break;
      }
    }

    if (parser.curToken.type == TokenType.TOKEN_EQUAL) {
      if (isEnum) {
        parserSyntaxError(parser);
      }

      eat(parser, TokenType.TOKEN_EQUAL);

      astVarDef.variableValue = parseExpression(parser, scope);

      switch (astVarDef.variableValue.type) {
        case ASTType.AST_CLASS:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_CLASS)
            parserTypeError(parser);
          break;
        case ASTType.AST_ENUM:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM)
            parserTypeError(parser);
          break;
        case ASTType.AST_STRING:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_STRING;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING)
            parserTypeError(parser);
          break;
        case ASTType.AST_INT:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_INT;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_INT)
            parserTypeError(parser);
          break;
        case ASTType.AST_DOUBLE:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_DOUBLE;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_DOUBLE)
            parserTypeError(parser);
          break;
        case ASTType.AST_BOOL:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_BOOL;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_BOOL)
            parserTypeError(parser);
          break;
        case ASTType.AST_LIST:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_LIST;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_LIST)
            parserTypeError(parser);
          break;
        case ASTType.AST_MAP:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_MAP;
            astVarDef.variableType = astType;
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_MAP)
            parserTypeError(parser);
          break;
        case ASTType.AST_COMPOUND:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_SOURCE)
            parserTypeError(parser);
          break;
        default:
          break;
      }
    }

    return astVarDef;
  }
}
