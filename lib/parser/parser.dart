import 'dart:isolate';

import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/constants.dart';
import 'package:Birb/utils/exceptions.dart';

import 'package:Birb/utils/AST.dart';
import 'data_type.dart';
import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/utils/scope.dart';
import 'package:Birb/lexer/token.dart';

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

/// Throws an UnexpectedTypeException
void parserTypeError(Parser parser) => throw UnexpectedTypeException(
    '[Line ${parser.lexer.lineNum}] Invalid type');

/// Throws a SyntaxException
void parserSyntaxError(Parser parser) =>
    throw SyntaxException('[Line ${parser.lexer.lineNum}] Syntax error');

/// Throws a UnexpectedTokenException
void parserUnexpectedToken(Parser parser, TokenType type) =>
    throw UnexpectedTokenException(
        '[Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, was expecting `$type`');

/// Sets the ast to be a child of a class
AST asClassChild(AST ast, AST object) {
  ast.isClassChild = true;
  ast.parent = object;
  return ast;
}

/// Check if the token is a DataType
bool isDataType(String tokenValue) {
  return tokenValue == 'Future' ||
      tokenValue == 'void' ||
      tokenValue == 'var' ||
      tokenValue == 'int' ||
      tokenValue == 'String' ||
      tokenValue == 'StrBuffer' ||
      tokenValue == 'double' ||
      tokenValue == 'bool' ||
      tokenValue == 'class' ||
      tokenValue == 'enum' ||
      tokenValue == 'List' ||
      tokenValue == 'Map' ||
      tokenValue == 'Source';
}

/// Check if the current token is a variable modifier
bool isModifier(String tokenValue) {
  return tokenValue == CONST || tokenValue == FINAL || tokenValue == STATIC;
}

/// Parses a single statement compound
/// ie:
/// ```dart
///  if (. . .)
///   screm("foo")
/// ```
AST parseOneStatementCompound(Parser parser, Scope scope) {
  var compound = initASTWithLine(CompoundNode(), parser.lexer.lineNum);
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

        if (isModifier(tokenValue)) {
          eat(parser, TokenType.TOKEN_ID);
          if (tokenValue == FINAL)
            return parseDefinition(parser, scope, false, true);

          return parseDefinition(parser, scope, true);
        }

        if (isDataType(tokenValue)) {
          return parseDefinition(parser, scope);
        }
        switch (tokenValue) {
          case WHILE:
            return parseWhile(parser, scope);
          case FOR:
            return parseFor(parser, scope);
          case IF:
            return parseIf(parser, scope);
          case SWITCH:
            return parseSwitch(parser, scope);
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

          var ast =
              initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
          ast.binaryOpLeft = a;
          ast.binaryOpRight = parseExpression(parser, scope);

          a = ast;
        }

        while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
          var astListAccess =
              initASTWithLine(ListAccessNode(), parser.lexer.lineNum);
          astListAccess.binaryOpLeft = a;
          eat(parser, TokenType.TOKEN_LBRACKET);
          astListAccess.listAccessPointer = parseExpression(parser, scope);
          eat(parser, TokenType.TOKEN_RBRACKET);

          a = astListAccess;
        }

        if (a != null) return a;
      }
      break;
    case TokenType.TOKEN_ANON_ID:
      // TODO(Calamity210): correct implementation to make it more scalable

      // @dart(alias) {}
      eat(parser, TokenType.TOKEN_ANON_ID);
      eat(parser, TokenType.TOKEN_ID);
      eat(parser, TokenType.TOKEN_LPAREN);

      AST astType = initASTWithLine(TypeNode(), parser.lexer.lineNum)
        ..scope = scope
        ..typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

      AST astVarDef = initASTWithLine(VarDefNode(), parser.lexer.lineNum)
        ..scope = scope
        ..variableName = parser.curToken.value
        ..variableType = astType
        ..isFinal = true;

      AST classAST = initASTWithLine(ClassNode(), parser.lexer.lineNum)
        ..scope = scope
        ..classChildren = [];

      Scope newScope = initScope(false);

      if (scope != null && scope.owner != null) newScope.owner = scope.owner;

      eat(parser, TokenType.TOKEN_ID);
      eat(parser, TokenType.TOKEN_RPAREN);

      int dartProgramStartIndex = parser.lexer.currentIndex;

      eat(parser, TokenType.TOKEN_LBRACE);

      if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
        if (parser.curToken.type == TokenType.TOKEN_ID)
          classAST.classChildren
              .add(asClassChild(parseDefinition(parser, newScope), classAST));

        while (parser.curToken.type == TokenType.TOKEN_SEMI ||
            (parser.prevToken.type == TokenType.TOKEN_RBRACE &&
                parser.curToken.type != TokenType.TOKEN_RBRACE)) {
          if (parser.curToken.type == TokenType.TOKEN_SEMI)
            eat(parser, TokenType.TOKEN_SEMI);

          if (parser.curToken.type == TokenType.TOKEN_ID)
            classAST.classChildren
                .add(asClassChild(parseDefinition(parser, newScope), classAST));
        }
      }
      String dartProgram = parser.lexer.program
          .substring(dartProgramStartIndex, parser.lexer.currentIndex)
          .trim();

      dartProgram = dartProgram.substring(0, dartProgram.length - 1);

      Uri dartProgramUri =
          Uri.dataFromString(dartProgram, mimeType: 'application/dart');

      Isolate.spawnUri(dartProgramUri, [], null);

      eat(parser, TokenType.TOKEN_RBRACE);

      astVarDef.variableValue = classAST;

      return astVarDef;
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

        AST astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
          ..binaryOpRight = parseStatement(parser, scope)
          ..binaryOperator = operator
          ..scope = scope;

        return astVarMod;
      }
      break;
    case TokenType.TOKEN_ANON_ID:
      throw UnexpectedTokenException(
          '[Line ${parser.lexer.lineNum}] Expected token `${parser.curToken.value}`');
      break;
    case TokenType.TOKEN_LBRACE:
      int lineNum = parser.lexer.lineNum;
      while (parser.curToken.type != TokenType.TOKEN_RBRACE) {
        if (parser.lexer.currentIndex == parser.lexer.program.length)
          throw UnexpectedTokenException(
              '[Lines $lineNum-${parser.lexer.lineNum}] No closing brace `}` was found');
        eat(parser, parser.curToken.type);
      }
      eat(parser, TokenType.TOKEN_RBRACE);

      return initASTWithLine(NoopNode(), lineNum);

    case TokenType.TOKEN_LBRACKET:
      int lineNum = parser.lexer.lineNum;
      while (parser.curToken.type != TokenType.TOKEN_RBRACKET) {
        if (parser.lexer.currentIndex == parser.lexer.program.length)
          throw UnexpectedTokenException(
              '[Lines $lineNum-${parser.lexer.lineNum}] No closing bracket `]` was found');
        eat(parser, parser.curToken.type);
      }
      eat(parser, TokenType.TOKEN_RBRACKET);
      eat(parser, TokenType.TOKEN_SEMI);

      return initASTWithLine(NoopNode(), lineNum);

    default:
      return initASTWithLine(NoopNode(), parser.lexer.lineNum);
  }

  return initASTWithLine(NoopNode(), parser.lexer.lineNum);
}

AST parseStatements(Parser parser, Scope scope) {
  var compound = initASTWithLine(CompoundNode(), parser.lexer.lineNum);
  compound.scope = scope;

  AST statement = parseStatement(parser, scope);

  compound.compoundValue.add(statement);

  while (parser.curToken.type == TokenType.TOKEN_SEMI ||
      parser.prevToken.type == TokenType.TOKEN_RBRACE &&
          statement.type != ASTType.AST_NOOP) {
    if (parser.curToken.type == TokenType.TOKEN_SEMI)
      eat(parser, TokenType.TOKEN_SEMI);

    statement = parseStatement(parser, scope);

    compound.compoundValue.add(statement);
  }

  return compound;
}

AST parseType(Parser parser, Scope scope) {
  AST astType = initASTWithLine(TypeNode(), parser.lexer.lineNum)
    ..scope = scope;

  var type = initDataType();

  var tokenValue = parser.curToken.value;

  switch (tokenValue) {
    case 'void':
      type.type = DATATYPE.DATA_TYPE_VOID;
      break;
    case 'String':
      type.type = DATATYPE.DATA_TYPE_STRING;
      break;
    case 'StrBuffer':
      type.type = DATATYPE.DATA_TYPE_STRING_BUFFER;
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
  var ast = initASTWithLine(DoubleNode(), parser.lexer.lineNum);
  ast.scope = scope;
  ast.doubleVal = double.parse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_DOUBLE_VALUE);

  return ast;
}

AST parseString(Parser parser, Scope scope) {
  var ast = initASTWithLine(StringNode(), parser.lexer.lineNum)
    ..scope = scope
    ..stringValue = parser.curToken.value;

  eat(parser, TokenType.TOKEN_STRING_VALUE);

  return ast;
}

AST parseInt(Parser parser, Scope scope) {
  var ast = initASTWithLine(IntNode(), parser.lexer.lineNum)
    ..scope = scope
    ..stringValue = parser.curToken.value
    ..intVal = int.parse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_INT_VALUE);

  return ast;
}

AST parseBool(Parser parser, Scope scope) {
  var ast = initASTWithLine(BoolNode(), parser.lexer.lineNum)..scope = scope;

  if (parser.curToken.value == 'false' || parser.curToken.value == 'true') {
    ast.boolVal = parser.curToken.value == 'true';
  } else {
    print('Expected a boolean value, but got ${parser.curToken.value}');
  }

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

AST parseNull(Parser parser, Scope scope) {
  var ast = initASTWithLine(NullNode(), parser.lexer.lineNum)..scope = scope;

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

AST parseVariable(Parser parser, Scope scope) {
  var ast = initASTWithLine(VariableNode(), parser.lexer.lineNum)
    ..scope = scope
    ..variableName = parser.prevToken.value;

  if (parser.curToken.type == TokenType.TOKEN_RBRACE) {
    var astAssign = initASTWithLine(VarAssignmentNode(), parser.lexer.lineNum)
      ..variableAssignmentLeft = ast
      ..variableValue = parseExpression(parser, scope)
      ..scope = scope;

    return astAssign;
  }

  if (parser.curToken.type == TokenType.TOKEN_EQUAL) {
    eat(parser, TokenType.TOKEN_EQUAL);
    var astAssign = initASTWithLine(VarAssignmentNode(), parser.lexer.lineNum);
    astAssign.variableAssignmentLeft = ast;
    astAssign.variableValue = parseExpression(parser, scope);
    astAssign.scope = scope;

    return astAssign;
  }
  if (parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_MUL_MUL) {
    Token operator = parser.curToken;

    eat(parser, operator.type);

    AST astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
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

    AST astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
      ..binaryOpLeft = ast
      ..binaryOpRight = parseExpression(parser, scope)
      ..binaryOperator = operator
      ..scope = scope;

    return astVarMod;
  }

  return ast;
}

AST parseBrace(Parser parser, Scope scope) {
  if (parser.prevToken.type != TokenType.TOKEN_ID)
    return parseMap(parser, scope);

  return parseClass(parser, scope);
}

AST parseClass(Parser parser, Scope scope) {
  AST ast = initASTWithLine(ClassNode(), parser.lexer.lineNum);

  ast.scope = scope;
  ast.classChildren = [];

  var newScope = initScope(false);

  if (scope != null) if (scope.owner != null) newScope.owner = scope.owner;

  eat(parser, TokenType.TOKEN_LBRACE);

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_ID) {
      ast.classChildren
          .add(asClassChild(parseDefinition(parser, newScope), ast));
    }

    while (parser.curToken.type == TokenType.TOKEN_SEMI ||
        (parser.prevToken.type == TokenType.TOKEN_RBRACE &&
            parser.curToken.type != TokenType.TOKEN_RBRACE)) {
      if (parser.curToken.type == TokenType.TOKEN_SEMI)
        eat(parser, TokenType.TOKEN_SEMI);

      if (parser.curToken.type == TokenType.TOKEN_ID) {
        ast.classChildren
            .add(asClassChild(parseDefinition(parser, newScope), ast));
      }
    }
  }

  eat(parser, TokenType.TOKEN_RBRACE);

  return ast;
}

AST parseEnum(Parser parser, Scope scope) {
  var ast = initASTWithLine(EnumNode(), parser.lexer.lineNum);
  ast.scope = scope;
  ast.enumElements = [];

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
      ast.enumElements.add(parseVariable(parser, newScope));
    }

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);

      if (parser.curToken.type == TokenType.TOKEN_ID) {
        eat(parser, TokenType.TOKEN_ID);
        ast.enumElements.add(parseVariable(parser, newScope));
      }
    }
  }

  eat(parser, TokenType.TOKEN_RBRACE);

  return ast;
}

AST parseMap(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_LBRACE);

  var ast = initASTWithLine(MapNode(), parser.lexer.lineNum);
  ast.scope = scope;
  ast.map = {};

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_STRING_VALUE) {
      String key = parser.curToken.value;
      eat(parser, TokenType.TOKEN_STRING_VALUE);

      if (parser.curToken.type == TokenType.TOKEN_COLON)
        eat(parser, TokenType.TOKEN_COLON);
      else
        throw UnexpectedTokenException(
            'Error: [Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, expected `:`.');

      if (parser.curToken.type == TokenType.TOKEN_COMMA)
        throw UnexpectedTokenException(
            'Error: [Line ${parser.lexer.lineNum}] Expected value for key `$key`');
      ast.map[key] = parseExpression(parser, scope);
    } else
      throw UnexpectedTokenException(
          'Error: [Line ${parser.lexer.lineNum}] Maps can only hold strings as keys.');
  }

  while (parser.curToken.type == TokenType.TOKEN_COMMA) {
    eat(parser, TokenType.TOKEN_COMMA);

    String key = parser.curToken.value;
    eat(parser, TokenType.TOKEN_STRING_VALUE);

    if (parser.curToken.type == TokenType.TOKEN_COLON)
      eat(parser, TokenType.TOKEN_COLON);
    else
      throw UnexpectedTokenException(
          'Error: [Line ${parser.lexer.lineNum}] Unexpected token `${parser.curToken.value}`, expected `:`.');

    if (parser.curToken.type == TokenType.TOKEN_COMMA)
      throw UnexpectedTokenException(
          'Error: [Line ${parser.lexer.lineNum}] Expected value for key `$key`');

    ast.map[key] = parseExpression(parser, scope);
  }

  eat(parser, TokenType.TOKEN_RBRACE);
  return ast;
}

AST parseList(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_LBRACKET);
  var ast = initASTWithLine(ListNode(), parser.lexer.lineNum);
  ast.scope = scope;
  ast.listElements = [];

  if (parser.curToken.type != TokenType.TOKEN_RBRACKET) {
    ast.listElements.add(parseExpression(parser, scope));
  }

  while (parser.curToken.type == TokenType.TOKEN_COMMA) {
    eat(parser, TokenType.TOKEN_COMMA);
    ast.listElements.add(parseExpression(parser, scope));
  }

  eat(parser, TokenType.TOKEN_RBRACKET);
  return ast;
}

AST parseFactor(Parser parser, Scope scope, bool isMap) {
  while (parser.curToken.type == TokenType.TOKEN_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB ||
      parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_NOT ||
      parser.curToken.type == TokenType.TOKEN_ONES_COMPLEMENT) {
    var unOpOperator = parser.curToken;
    eat(parser, unOpOperator.type);

    var ast = initASTWithLine(UnaryOpNode(), parser.lexer.lineNum);
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
  }

  if (parser.curToken.type == TokenType.TOKEN_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB ||
      parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_NOT ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_AND ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_OR ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_XOR ||
      parser.curToken.type == TokenType.TOKEN_LSHIFT ||
      parser.curToken.type == TokenType.TOKEN_RSHIFT) {
    eat(parser, parser.curToken.type);

    var a = parseVariable(parser, scope).binaryOpRight;

    if (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      ast.binaryOpRight = parseFactor(parser, scope, false);

      a = ast;
    }

    while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
      var astListAccess =
          initASTWithLine(ListAccessNode(), parser.lexer.lineNum);
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
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      ast.binaryOpRight = parseFactor(parser, scope, false);

      a = ast;
    }

    while (parser.curToken.type == TokenType.TOKEN_LBRACKET) {
      var astListAccess =
          initASTWithLine(ListAccessNode(), parser.lexer.lineNum);
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
      return parseBrace(parser, scope);
    case TokenType.TOKEN_LBRACKET:
      return parseList(parser, scope);
    default:
      throw UnexpectedTokenException('Unexpected ${parser.curToken.value}');
      break;
  }
}

AST parseTerm(Parser parser, Scope scope) {
  var tokenValue = parser.curToken.value;

  if (isModifier(tokenValue)) {
    eat(parser, TokenType.TOKEN_ID);
    if (tokenValue == FINAL) return parseDefinition(parser, scope, false, true);

    return parseDefinition(parser, scope, true);
  }

  if (isDataType(tokenValue)) return parseDefinition(parser, scope);

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

    astBinaryOp = initASTWithLine(BinaryOpNode(), parser.lexer.lineNum);

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
      parser.curToken.type == TokenType.TOKEN_SUB_SUB ||
      parser.curToken.type == TokenType.TOKEN_NOT ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_AND ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_OR ||
      parser.curToken.type == TokenType.TOKEN_BITWISE_XOR ||
      parser.curToken.type == TokenType.TOKEN_LSHIFT ||
      parser.curToken.type == TokenType.TOKEN_RSHIFT) {
    if (parser.curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        parser.curToken.type == TokenType.TOKEN_SUB_SUB) {
      var binaryOp = parser.curToken;
      eat(parser, binaryOp.type);

      astBinaryOp = initASTWithLine(BinaryOpNode(), parser.lexer.lineNum);
      astBinaryOp.scope = scope;

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOp;
      astBinaryOp.binaryOpRight = parseTerm(parser, scope);

      node = astBinaryOp;
    } else {
      var binaryOp = parser.curToken;
      eat(parser, binaryOp.type);

      astBinaryOp = initASTWithLine(BinaryOpNode(), parser.lexer.lineNum);
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

    astBinaryOp = initASTWithLine(BinaryOpNode(), parser.lexer.lineNum);
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

  return initASTWithLine(BreakNode(), parser.lexer.lineNum);
}

AST parseContinue(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  return initASTWithLine(ContinueNode(), parser.lexer.lineNum);
}

AST parseReturn(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ReturnNode(), parser.lexer.lineNum)
    ..scope = scope
    ..returnValue = parseExpression(parser, scope) ?? NullNode();

  return ast;
}

AST parseIf(Parser parser, Scope scope) {
  var ast = initASTWithLine(IfNode(), parser.lexer.lineNum);
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
        var compound = initASTWithLine(CompoundNode(), parser.lexer.lineNum);
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

AST parseSwitch(Parser parser, Scope scope) {
  AST switchAST = initASTWithLine(SwitchNode(), parser.lexer.lineNum)
    ..switchCases = {};

  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);

  switchAST.switchExpression = parseExpression(parser, scope);

  eat(parser, TokenType.TOKEN_RPAREN);
  eat(parser, TokenType.TOKEN_LBRACE);
  eat(parser, TokenType.TOKEN_ID);

  AST caseAST = parseStatement(parser, scope);

  eat(parser, TokenType.TOKEN_COLON);
  eat(parser, TokenType.TOKEN_LBRACE);

  AST caseFuncAST = parseStatements(parser, scope);

  eat(parser, TokenType.TOKEN_RBRACE);

  switchAST.switchCases[caseAST] = caseFuncAST;

  while (parser.curToken.value == CASE) {
    eat(parser, TokenType.TOKEN_ID);

    caseAST = parseStatement(parser, scope);

    eat(parser, TokenType.TOKEN_COLON);
    eat(parser, TokenType.TOKEN_LBRACE);

    caseFuncAST = parseStatements(parser, scope);

    eat(parser, TokenType.TOKEN_RBRACE);

    switchAST.switchCases[caseAST] = caseFuncAST;
  }

  // Default case (REQUIRED)
  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_COLON);
  eat(parser, TokenType.TOKEN_LBRACE);

  AST defaultFuncAST = parseStatements(parser, scope);

  eat(parser, TokenType.TOKEN_RBRACE);

  switchAST.switchDefault = defaultFuncAST;

  eat(parser, TokenType.TOKEN_RBRACE);

  return switchAST;
}

AST parseTernary(Parser parser, Scope scope, AST expr) {
  var ternary = initASTWithLine(TernaryNode(), parser.lexer.lineNum);
  ternary.ternaryExpression = expr;

  eat(parser, TokenType.TOKEN_QUESTION);

  ternary.ternaryBody = parseTerm(parser, scope);

  eat(parser, TokenType.TOKEN_COLON);

  ternary.ternaryElseBody = parseTerm(parser, scope);

  return ternary;
}

AST parseIterate(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var astVar = parseExpression(parser, scope);
  eat(parser, TokenType.TOKEN_ID);

  AST astFuncName;

  if (isModifier(parser.curToken.value)) {
    eat(parser, TokenType.TOKEN_ID);
    if (parser.curToken.value == FINAL)
      return parseDefinition(parser, scope, false, true);

    return parseDefinition(parser, scope, true);
  }

  if (isDataType(parser.curToken.value)) {
    astFuncName = parseDefinition(parser, scope);
  } else {
    eat(parser, TokenType.TOKEN_ID);
    astFuncName = parseVariable(parser, scope);
  }

  var ast = initASTWithLine(IterateNode(), parser.lexer.lineNum);
  ast.iterateIterable = astVar;
  ast.iterateFunction = astFuncName;

  return ast;
}

AST parseAssert(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(AssertNode(), parser.lexer.lineNum);
  ast.assertExpression = parseExpression(parser, scope);

  return ast;
}

AST parseWhile(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);
  var ast = initASTWithLine(WhileNode(), parser.lexer.lineNum);
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
  var ast = ForNode();

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
  var ast = initASTWithLine(FuncCallNode(), parser.lexer.lineNum);
  ast.funcCallExpression = expr;
  eat(parser, TokenType.TOKEN_LPAREN);

  ast.scope = scope;

  if (parser.curToken.type != TokenType.TOKEN_RPAREN) {
    var astExpr = parseExpression(parser, scope);

    if (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var astAttAccess =
          initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      astAttAccess.binaryOpLeft = astExpr;
      astAttAccess.binaryOpRight = parseFactor(parser, scope, false);

      astExpr = astAttAccess;
    }

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

AST parseDefinition(Parser parser, Scope scope,
    [bool isConst = false, bool isFinal = false]) {
  AST astType = parseType(parser, scope);

  parser.dataType = astType.typeValue;

  String name;
  bool isEnum = false;

  if (parser.prevToken.value == 'StrBuffer' &&
      parser.curToken.type == TokenType.TOKEN_LPAREN)
    return parseStrBuffer(parser, scope, isConst, isFinal);

  if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM) {
    name = parser.curToken.value;

    if (parser.curToken.type == TokenType.TOKEN_ID)
      eat(parser, TokenType.TOKEN_ID);
    else
      eat(parser, TokenType.TOKEN_ANON_ID);
  } else
    isEnum = true;

  // Function Definition
  if (parser.curToken.type == TokenType.TOKEN_LPAREN) {
    return parseFunctionDefinition(parser, scope, name, astType);
  } else {
    return parseVariableDefinition(
        parser, scope, name, astType, isEnum, isConst, isFinal);
  }
}

AST parseFunctionDefinition(
    Parser parser, Scope scope, String funcName, AST astType) {
  var ast = initASTWithLine(FuncDefNode(), parser.lexer.lineNum)
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

  if (parser.curToken.type == TokenType.TOKEN_INLINE) {
    eat(parser, TokenType.TOKEN_INLINE);
    ast.funcDefBody = parseStatement(parser, newScope);
    ast.funcDefBody.scope = newScope;
    return ast;
  }

  if (parser.curToken.type == TokenType.TOKEN_RBRACE) {
    AST childDef;

    if (isModifier(parser.curToken.value)) {
      eat(parser, TokenType.TOKEN_ID);
      if (parser.curToken.value == FINAL)
        return parseDefinition(parser, scope, false, true);

      return parseDefinition(parser, scope, true);
    }
    if (isDataType(parser.curToken.value)) {
      childDef = parseDefinition(parser, scope);
    } else {
      eat(parser, TokenType.TOKEN_ID);
      childDef = parseVariable(parser, scope);
    }

    childDef.scope = newScope;
    ast.compChildren.add(childDef);

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);

      if (isModifier(parser.curToken.value)) {
        eat(parser, TokenType.TOKEN_ID);
        if (parser.curToken.value == FINAL)
          return parseDefinition(parser, scope, false, true);

        return parseDefinition(parser, scope, true);
      }

      if (isDataType(parser.curToken.value)) {
        childDef = parseDefinition(parser, scope);
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

    if (isModifier(parser.curToken.value)) {
      eat(parser, TokenType.TOKEN_ID);
      if (parser.curToken.value == FINAL)
        return parseDefinition(parser, scope, false, true);

      return parseDefinition(parser, scope, true);
    }

    if (isDataType(parser.curToken.value)) {
      childDef = parseDefinition(parser, scope);
    } else {
      eat(parser, TokenType.TOKEN_ID);
      childDef = parseVariable(parser, scope);
    }

    childDef.scope = newScope;
    ast.compChildren.add(childDef);

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);

      if (isModifier(parser.curToken.value)) {
        eat(parser, TokenType.TOKEN_ID);
        if (parser.curToken.value == FINAL)
          return parseDefinition(parser, scope, false, true);

        return parseDefinition(parser, scope, true);
      }

      if (isDataType(parser.curToken.value)) {
        childDef = parseDefinition(parser, scope);
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
}

AST parseVariableDefinition(
    Parser parser, Scope scope, String name, AST astType,
    [bool isEnum = false, bool isConst = false, bool isFinal = false]) {
  var astVarDef = initASTWithLine(VarDefNode(), parser.lexer.lineNum)
    ..scope = scope
    ..variableName = name
    ..variableType = astType
    ..isFinal = isFinal;

  if (isEnum) {
    var astType = initASTWithLine(TypeNode(), parser.lexer.lineNum);
    astType.scope = scope;

    var type = initDataType()..type = DATATYPE.DATA_TYPE_ENUM;
    astType.typeValue = type;

    astVarDef.variableType = astType;
    astVarDef.variableValue = parseEnum(parser, scope);
    astVarDef.variableName = parser.curToken.value;
    eat(parser, TokenType.TOKEN_ID);
  }

  // Class
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
      case ASTType.AST_COMPOUND:
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_SOURCE)
          parserTypeError(parser);
        break;
      default:
        break;
    }
  }

  if (parser.curToken.type == TokenType.TOKEN_EQUAL) {
    if (isEnum) parserSyntaxError(parser);

    eat(parser, TokenType.TOKEN_EQUAL);

    astVarDef.variableValue = parseExpression(parser, scope);

    if (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var astAttAccess =
          initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      astAttAccess.binaryOpLeft = astVarDef.variableValue;
      astAttAccess.binaryOpRight = parseFactor(parser, scope, false);

      astVarDef.variableValue = astAttAccess;
    }

    switch (astVarDef.variableValue.type) {
      case ASTType.AST_STRING:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_STRING;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.stringValue}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING)
          parserTypeError(parser);
        break;
      case ASTType.AST_STRING_BUFFER:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_STRING_BUFFER;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program.replaceAll(
                name, '${astVarDef.variableValue.strBuffer.toString()}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING_BUFFER)
          parserTypeError(parser);
        break;
      case ASTType.AST_INT:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_INT;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.intVal}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_INT)
          parserTypeError(parser);
        break;
      case ASTType.AST_DOUBLE:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_DOUBLE;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.doubleVal}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_DOUBLE)
          parserTypeError(parser);
        break;
      case ASTType.AST_BOOL:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_BOOL;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.boolVal}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_BOOL)
          parserTypeError(parser);
        break;
      case ASTType.AST_LIST:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_LIST;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.listElements}');
        }
        if (astType.typeValue.type != DATATYPE.DATA_TYPE_LIST)
          parserTypeError(parser);
        break;
      case ASTType.AST_MAP:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_MAP;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program
                .replaceAll(name, '${astVarDef.variableValue.map}');
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

AST parseStrBuffer(Parser parser, Scope scope,
    [bool isConst = false, bool isFinal = false]) {
  eat(parser, TokenType.TOKEN_LPAREN);
  AST strBufferAST = initASTWithLine(StrBufferNode(), parser.lexer.lineNum)
    ..strBuffer = StringBuffer(parser.curToken.value)
    ..isFinal = isFinal;

  eat(parser, TokenType.TOKEN_STRING_VALUE);
  eat(parser, TokenType.TOKEN_RPAREN);

  return strBufferAST;
}
