import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/constants.dart';
import 'package:Birb/utils/exceptions.dart';

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
ASTNode asClassChild(ASTNode ast, ASTNode object) {
  ast.isClassChild = true;
  ast.parent = object;
  return ast;
}

/// Check if the token is a DataType
bool isDataType(Parser parser) {
  String tokenValue = parser.curToken.value;

  List dataTypes = [
    'void',
    'var',
    'int',
    'String',
    'StrBuffer',
    'double',
    'bool',
    'class',
    'enum',
    'List',
    'Map',
    'Source'
  ];

  int lineNum = parser.lexer.lineNum;
  int curIndex = parser.lexer.currentIndex;
  String curChar = parser.lexer.currentChar;

  bool isDot = getNextToken(parser.lexer).type == TokenType.TOKEN_DOT;

  parser.lexer
    ..lineNum = lineNum
    ..currentIndex = curIndex
    ..currentChar = curChar;

  for (String type in dataTypes) {
    if (!isDot && type == tokenValue || type + '?' == tokenValue) return true;
  }

  return false;
}

/// Check if the current token is a variable modifier
bool isModifier(String tokenValue) {
  return tokenValue == CONST || tokenValue == FINAL;
}

/// Parses a single statement compound
/// ie:
/// ```dart
///  if (. . .)
///   screm("foo")
/// ```
ASTNode parseOneStatementCompound(Parser parser, Scope scope) {
  var compound = initASTWithLine(CompoundNode(), parser.lexer.lineNum);
  compound.scope = scope;

  var statement = parseStatement(parser, scope);
  compound.compoundValue.add(statement);

  return compound;
}

ASTNode parse(Parser parser, {Scope scope}) {
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

ASTNode parseStatement(Parser parser, Scope scope) {
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

        if (isDataType(parser)) {
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
          case THROW:
            return parseThrow(parser, scope);
          case BREAK:
            return parseBreak(parser, scope);
          case NEXT:
            return parseNext(parser, scope);
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
          var ast =
              initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
          ast.binaryOpLeft = a;
          eat(parser, TokenType.TOKEN_ID);
          var varAST = parseVariable(parser, scope);
          ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
              ? parseFuncCall(parser, scope, varAST)
              : varAST;
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
    case TokenType.TOKEN_LESS_THAN:
      eat(parser, TokenType.TOKEN_LESS_THAN);

      String annotation = parser.curToken.value;
      eat(parser, TokenType.TOKEN_ID);

      eat(parser, TokenType.TOKEN_GREATER_THAN);

      switch (annotation) {
        case SUPERSEDE:
          return parseDefinition(
              parser,
              scope,
              parser.curToken.value == 'const',
              parser.curToken.value == 'final',
              true);
        default:
          throw UnexpectedTokenException(
              'No annotation ${parser.curToken.value} found!');
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

        ASTNode astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
          ..binaryOpRight = parseStatement(parser, scope)
          ..binaryOperator = operator
          ..scope = scope;

        return astVarMod;
      }
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
      return parseList(parser, scope);

    default:
      return initASTWithLine(NoopNode(), parser.lexer.lineNum);
  }

  return initASTWithLine(NoopNode(), parser.lexer.lineNum);
}

ASTNode parseStatements(Parser parser, Scope scope) {
  var compound = initASTWithLine(CompoundNode(), parser.lexer.lineNum);
  compound.scope = scope;

  ASTNode statement = parseStatement(parser, scope);

  compound.compoundValue.add(statement);

  while (parser.curToken.type == TokenType.TOKEN_SEMI ||
      parser.prevToken.type == TokenType.TOKEN_RBRACE &&
          statement.type != ASTType.AST_NOOP) {
    if (parser.curToken.type == TokenType.TOKEN_SEMI)
      eat(parser, TokenType.TOKEN_SEMI);

    statement = parseStatement(parser, scope);

    compound.compoundValue.add(statement);
  }

  if (parser.curToken.type != TokenType.TOKEN_RBRACE &&
      parser.lexer.currentIndex != parser.lexer.program.length)
    throw UnexpectedTokenException(
        'Error [Line ${parser.lexer.lineNum}]: Expected `;` but found `${parser.curToken.value}`');

  return compound;
}

ASTNode parseType(Parser parser, Scope scope) {
  ASTNode astType = initASTWithLine(TypeNode(), parser.lexer.lineNum)
    ..scope = scope;

  var type = initDataType();

  var tokenValue = parser.curToken.value;

  if (tokenValue.endsWith('?'))
    tokenValue = tokenValue.replaceRange(tokenValue.length- 1, tokenValue.length, '');

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

ASTNode parseDouble(Parser parser, Scope scope) {
  var ast = initASTWithLine(DoubleNode(), parser.lexer.lineNum);
  ast.scope = scope;
  ast.doubleVal = double.parse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_DOUBLE_VALUE);

  return ast;
}

ASTNode parseString(Parser parser, Scope scope) {
  var ast = initASTWithLine(StringNode(), parser.lexer.lineNum)
    ..scope = scope
    ..stringValue = parser.curToken.value;

  eat(parser, TokenType.TOKEN_STRING_VALUE);

  return ast;
}

ASTNode parseInt(Parser parser, Scope scope) {
  var ast = initASTWithLine(IntNode(), parser.lexer.lineNum)
    ..scope = scope
    ..intVal = int.tryParse(parser.curToken.value);

  eat(parser, TokenType.TOKEN_INT_VALUE);

  return ast;
}

ASTNode parseBool(Parser parser, Scope scope) {
  var ast = initASTWithLine(BoolNode(), parser.lexer.lineNum)..scope = scope;

  if (parser.curToken.value == 'false' || parser.curToken.value == 'true') {
    ast.boolVal = parser.curToken.value == 'true';
  } else {
    print('Expected a boolean value, but got ${parser.curToken.value}');
  }

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

ASTNode parseNull(Parser parser, Scope scope) {
  var ast = initASTWithLine(NullNode(), parser.lexer.lineNum)..scope = scope;

  eat(parser, TokenType.TOKEN_ID);

  return ast;
}

ASTNode parseVariable(Parser parser, Scope scope) {
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

    ASTNode astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
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

    ASTNode astVarMod = initASTWithLine(VarModNode(), parser.lexer.lineNum)
      ..binaryOpLeft = ast
      ..binaryOpRight = parseExpression(parser, scope)
      ..binaryOperator = operator
      ..scope = scope;

    return astVarMod;
  }

  return ast;
}

ASTNode parseBrace(Parser parser, Scope scope) {
  if (parser.prevToken.type != TokenType.TOKEN_ID)
    return parseMap(parser, scope);

  return parseClass(parser, scope);
}

ASTNode parseClass(Parser parser, Scope scope) {
  ASTNode ast = initASTWithLine(ClassNode(), parser.lexer.lineNum)
    ..scope = scope
    ..className = parser.prevToken.value
    ..classChildren = [];

  var newScope = initScope(false);

  if (scope != null) if (scope.owner != null) newScope.owner = scope.owner;

  eat(parser, TokenType.TOKEN_LBRACE);

  if (parser.curToken.type != TokenType.TOKEN_RBRACE) {
    if (parser.curToken.type == TokenType.TOKEN_ID ||
        parser.curToken.type == TokenType.TOKEN_LESS_THAN) {
      ast.classChildren
          .add(asClassChild(parseDefinition(parser, newScope), ast));
    }

    while (parser.curToken.type == TokenType.TOKEN_SEMI ||
        (parser.prevToken.type == TokenType.TOKEN_RBRACE &&
            parser.curToken.type != TokenType.TOKEN_RBRACE)) {
      if (parser.curToken.type == TokenType.TOKEN_SEMI)
        eat(parser, TokenType.TOKEN_SEMI);

      if (parser.curToken.type == TokenType.TOKEN_ID ||
          parser.curToken.type == TokenType.TOKEN_LESS_THAN) {
        ast.classChildren
            .add(asClassChild(parseDefinition(parser, newScope), ast));
      }
    }
  }

  eat(parser, TokenType.TOKEN_RBRACE);

  return ast;
}

ASTNode parseEnum(Parser parser, Scope scope) {
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

ASTNode parseMap(Parser parser, Scope scope) {
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

ASTNode parseList(Parser parser, Scope scope) {
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

ASTNode parseFactor(Parser parser, Scope scope, bool isMap) {
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
    case NEW:
      return parseNew(parser, scope);
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

    while (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      eat(parser, TokenType.TOKEN_ID);
      var varAST = parseVariable(parser, scope);
      ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
          ? parseFuncCall(parser, scope, varAST)
          : varAST;
      a = ast;
    }

    while (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      eat(parser, TokenType.TOKEN_ID);
      var varAST = parseVariable(parser, scope);
      ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
          ? parseFuncCall(parser, scope, varAST)
          : varAST;
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

    while (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = a;
      eat(parser, TokenType.TOKEN_ID);
      var varAST = parseVariable(parser, scope);
      ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
          ? parseFuncCall(parser, scope, varAST)
          : varAST;
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

ASTNode parseTerm(Parser parser, Scope scope, {bool isFuncDefArgs = false}) {
  var tokenValue = parser.curToken.value;

  if (isModifier(tokenValue)) {
    eat(parser, TokenType.TOKEN_ID);
    if (tokenValue == FINAL) return parseDefinition(parser, scope, false, true, false, true);

    return parseDefinition(parser, scope, true, false, false, true);
  }

  if (isDataType(parser)) return parseDefinition(parser, scope, false, false, false, true);

  var node = parseFactor(parser, scope, false);
  ASTNode astBinaryOp;

  if (parser.curToken.type == TokenType.TOKEN_LPAREN)
    node = parseFuncCall(parser, scope, node);

  while (parser.curToken.type == TokenType.TOKEN_DIV ||
      parser.curToken.type == TokenType.TOKEN_MUL ||
      parser.curToken.type == TokenType.TOKEN_LESS_THAN ||
      parser.curToken.type == TokenType.TOKEN_GREATER_THAN ||
      parser.curToken.type == TokenType.TOKEN_LESS_THAN_EQUAL ||
      parser.curToken.type == TokenType.TOKEN_GREATER_THAN_EQUAL ||
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

ASTNode parseExpression(Parser parser, Scope scope, {bool isFuncDefArgs = false}) {
  var node = parseTerm(parser, scope, isFuncDefArgs: isFuncDefArgs);
  ASTNode astBinaryOp;

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
      astBinaryOp.binaryOpRight = parseTerm(parser, scope, isFuncDefArgs: isFuncDefArgs);

      node = astBinaryOp;
    } else {
      var binaryOp = parser.curToken;
      eat(parser, binaryOp.type);

      astBinaryOp = initASTWithLine(BinaryOpNode(), parser.lexer.lineNum);
      astBinaryOp.scope = scope;

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOp;
      astBinaryOp.binaryOpRight = parseTerm(parser, scope, isFuncDefArgs: isFuncDefArgs);

      node = astBinaryOp;
    }
  }

  while (parser.curToken.type == TokenType.TOKEN_AND ||
      parser.curToken.type == TokenType.TOKEN_OR) {
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

ASTNode parseBreak(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  return initASTWithLine(BreakNode(), parser.lexer.lineNum);
}

ASTNode parseNext(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  return initASTWithLine(NextNode(), parser.lexer.lineNum);
}

ASTNode parseNew(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);

  ASTNode newAST = initASTWithLine(NewNode(), parser.lexer.lineNum)
    ..newValue = parseExpression(parser, scope);

  return newAST;
}

ASTNode parseReturn(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ReturnNode(), parser.lexer.lineNum)
    ..scope = scope
    ..returnValue = parseExpression(parser, scope) ?? NullNode();

  return ast;
}

ASTNode parseThrow(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(ThrowNode(), parser.lexer.lineNum)
    ..scope = scope
    ..throwValue = parseExpression(parser, scope) ?? NullNode();

  return ast;
}

ASTNode parseIf(Parser parser, Scope scope) {
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

ASTNode parseSwitch(Parser parser, Scope scope) {
  ASTNode switchAST = initASTWithLine(SwitchNode(), parser.lexer.lineNum)
    ..switchCases = {};

  eat(parser, TokenType.TOKEN_ID);
  eat(parser, TokenType.TOKEN_LPAREN);

  switchAST.switchExpression = parseExpression(parser, scope);

  eat(parser, TokenType.TOKEN_RPAREN);
  eat(parser, TokenType.TOKEN_LBRACE);
  eat(parser, TokenType.TOKEN_ID);

  ASTNode caseAST = parseStatement(parser, scope);

  eat(parser, TokenType.TOKEN_COLON);
  eat(parser, TokenType.TOKEN_LBRACE);

  ASTNode caseFuncAST = parseStatements(parser, scope);

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

  ASTNode defaultFuncAST = parseStatements(parser, scope);

  eat(parser, TokenType.TOKEN_RBRACE);

  switchAST.switchDefault = defaultFuncAST;

  eat(parser, TokenType.TOKEN_RBRACE);

  return switchAST;
}

ASTNode parseTernary(Parser parser, Scope scope, ASTNode expr) {
  var ternary = initASTWithLine(TernaryNode(), parser.lexer.lineNum);
  ternary.ternaryExpression = expr;

  eat(parser, TokenType.TOKEN_QUESTION);

  ternary.ternaryBody = parseTerm(parser, scope);

  eat(parser, TokenType.TOKEN_COLON);

  ternary.ternaryElseBody = parseTerm(parser, scope);

  return ternary;
}

ASTNode parseIterate(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var astVar = parseExpression(parser, scope);
  eat(parser, TokenType.TOKEN_ID);

  ASTNode astFuncName;

  if (isModifier(parser.curToken.value)) {
    eat(parser, TokenType.TOKEN_ID);
    if (parser.curToken.value == FINAL)
      return parseDefinition(parser, scope, false, true);

    return parseDefinition(parser, scope, true);
  }

  if (isDataType(parser)) {
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

ASTNode parseAssert(Parser parser, Scope scope) {
  eat(parser, TokenType.TOKEN_ID);
  var ast = initASTWithLine(AssertNode(), parser.lexer.lineNum);
  ast.assertExpression = parseExpression(parser, scope);

  return ast;
}

ASTNode parseWhile(Parser parser, Scope scope) {
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

ASTNode parseFor(Parser parser, Scope scope) {
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

ASTNode parseFuncCall(Parser parser, Scope scope, ASTNode expr) {
  var ast = initASTWithLine(FuncCallNode(), parser.lexer.lineNum);
  ast.funcCallExpression = expr;
  eat(parser, TokenType.TOKEN_LPAREN);

  ast.scope = scope;

  if (parser.curToken.type != TokenType.TOKEN_RPAREN) {
    var astExpr = parseExpression(parser, scope);

    while (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = astExpr;
      eat(parser, TokenType.TOKEN_ID);
      var varAST = parseVariable(parser, scope);
      ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
          ? parseFuncCall(parser, scope, varAST)
          : varAST;
      astExpr = ast;
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

ASTNode parseDefinition(Parser parser, Scope scope,
    [bool isConst = false, bool isFinal = false, bool isSuperseding = false, bool isFuncDefArgs = false]) {
  if (parser.curToken.type == TokenType.TOKEN_LESS_THAN) {
    eat(parser, TokenType.TOKEN_LESS_THAN);

    String annotation = parser.curToken.value;
    eat(parser, TokenType.TOKEN_ID);

    eat(parser, TokenType.TOKEN_GREATER_THAN);

    switch (annotation) {
      case SUPERSEDE:
        isConst = parser.curToken.value == 'const';
        isFinal = parser.curToken.value == 'final';
        isSuperseding = true;
        break;
      default:
        throw UnexpectedTokenException(
            'No annotation `${parser.curToken.value}` found!');
    }
  }

  bool isNullable = parser.curToken.value.endsWith('?');

  // TODO (Calamity): refactor
  if (parser.curToken.value == 'const') {
    isConst = true;
    eat(parser, TokenType.TOKEN_ID);
  }

  ASTNode astType = parseType(parser, scope);

  parser.dataType = astType.typeValue;

  String name;
  bool isEnum = false;

  // TODO (Calamity): refactor
  if (parser.prevToken.value == 'StrBuffer' &&
      parser.curToken.type == TokenType.TOKEN_LPAREN) {
    var strBuffer = parseStrBuffer(parser, scope, isConst, isFinal);
    if (isNullable) {
      strBuffer.isNullable = true;
    } else if (!isFuncDefArgs && strBuffer.variableValue == null
        || strBuffer.variableValue is NullNode) {
      throw UnexpectedTypeException('Error [Line: ${parser.lexer.lineNum}]Non-nullable variables cannot be given a null value, add the `?` suffix to a variable type to make it nullable');
    }

    return strBuffer;
  }

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
    var varDef = parseVariableDefinition(
        parser, scope, name, astType, isEnum, isConst, isFinal, isSuperseding);

    if (isNullable) {
      varDef.isNullable = true;
    } else if (!isFuncDefArgs && varDef.variableValue == null
        || varDef.variableValue is NullNode) {
      throw UnexpectedTypeException('Error [Line ${parser.lexer.lineNum}]: Non-nullable variables cannot be given a null value, add the `?` suffix to a variable type to make it nullable');
   }

    return varDef;
  }
}

ASTNode parseFunctionDefinition(
    Parser parser, Scope scope, String funcName, ASTNode astType) {
  var ast = initASTWithLine(FuncDefNode(), parser.lexer.lineNum)
    ..funcName = funcName
    ..funcDefType = astType
    ..funcDefArgs = [];

  var newScope = initScope(false)..owner = ast;

  eat(parser, TokenType.TOKEN_LPAREN);

  if (parser.curToken.type != TokenType.TOKEN_RPAREN) {
    ast.funcDefArgs.add(parseExpression(parser, scope, isFuncDefArgs: true));

    while (parser.curToken.type == TokenType.TOKEN_COMMA) {
      eat(parser, TokenType.TOKEN_COMMA);
      ast.funcDefArgs.add(parseExpression(parser, scope, isFuncDefArgs: true));
    }
  }

  eat(parser, TokenType.TOKEN_RPAREN);

  if (parser.curToken.type == TokenType.TOKEN_INLINE) {
    eat(parser, TokenType.TOKEN_INLINE);
    ast.funcDefBody = parseOneStatementCompound(parser, newScope);
    ast.funcDefBody.scope = newScope;

    return ast;
  }

  if (parser.curToken.type == TokenType.TOKEN_RBRACE) {
    ASTNode childDef;

    if (isModifier(parser.curToken.value)) {
      eat(parser, TokenType.TOKEN_ID);
      if (parser.curToken.value == FINAL)
        return parseDefinition(parser, scope, false, true);

      return parseDefinition(parser, scope, true);
    }
    if (isDataType(parser)) {
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

      if (isDataType(parser)) {
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

    ASTNode childDef;

    if (isModifier(parser.curToken.value)) {
      eat(parser, TokenType.TOKEN_ID);
      if (parser.curToken.value == FINAL)
        return parseDefinition(parser, scope, false, true);

      return parseDefinition(parser, scope, true);
    }

    if (isDataType(parser)) {
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

      if (isDataType(parser)) {
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

ASTNode parseVariableDefinition(
    Parser parser, Scope scope, String name, ASTNode astType,
    [bool isEnum = false,
    bool isConst = false,
    bool isFinal = false,
    bool isSuperseding = false]) {
  var astVarDef = initASTWithLine(VarDefNode(), parser.lexer.lineNum)
    ..scope = scope
    ..variableName = name
    ..variableType = astType
    ..isFinal = isFinal
    ..isSuperseding = isSuperseding;

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

  if (parser.curToken.value == 'follows') {
    eat(parser, TokenType.TOKEN_ID);

    VariableNode superClass =
        initASTWithLine(VariableNode(), parser.lexer.lineNum)
          ..scope = scope
          ..variableName = parser.curToken.value;

    eat(parser, TokenType.TOKEN_ID);

    astVarDef.variableValue = parseClass(parser, scope);
    astVarDef.variableValue.superClass = superClass;

    return astVarDef;
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

    while (parser.curToken.type == TokenType.TOKEN_DOT) {
      eat(parser, TokenType.TOKEN_DOT);
      var ast = initASTWithLine(AttributeAccessNode(), parser.lexer.lineNum);
      ast.binaryOpLeft = astVarDef.variableValue;
      eat(parser, TokenType.TOKEN_ID);
      var varAST = parseVariable(parser, scope);
      ast.binaryOpRight = parser.curToken.type == TokenType.TOKEN_LPAREN
          ? parseFuncCall(parser, scope, varAST)
          : varAST;
      astVarDef.variableValue = ast;
    }

    switch (astVarDef.variableValue.type) {
      case ASTType.AST_STRING:
        if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
          astType.typeValue.type = DATATYPE.DATA_TYPE_STRING;
          astVarDef.variableType = astType;
          if (isConst)
            parser.lexer.program = parser.lexer.program.replaceAll(
                RegExp('[^"\'](?:${astVarDef.parent.className})?$name[^"\']'),
                '${astVarDef.variableValue.stringValue}');
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

ASTNode parseStrBuffer(Parser parser, Scope scope,
    [bool isConst = false, bool isFinal = false]) {
  eat(parser, TokenType.TOKEN_LPAREN);
  ASTNode strBufferAST = initASTWithLine(StrBufferNode(), parser.lexer.lineNum)
    ..strBuffer = StringBuffer(parser.curToken.value)
    ..isFinal = isFinal;

  eat(parser, TokenType.TOKEN_STRING_VALUE);
  eat(parser, TokenType.TOKEN_RPAREN);

  return strBufferAST;
}
