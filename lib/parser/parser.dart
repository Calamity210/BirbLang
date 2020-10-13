import 'dart:collection';

import 'package:Birb/parser/data_type.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/constants.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/utils/scope.dart';
import 'package:Birb/lexer/token.dart';


class Parser {

  Parser(this.lexer) {
    curToken = lexer.getNextToken();
  }

  Lexer lexer;
  Token prevToken;
  Token curToken;
  DataType dataType;


  /// Throws an UnexpectedTypeException
  void parserTypeError() => throw UnexpectedTypeException(
      '[Line ${lexer.lineNum}] Invalid type');

  /// Throws a SyntaxException
  void parserSyntaxError() =>
      throw SyntaxException('[Line ${lexer.lineNum}] Syntax error');

  /// Throws a UnexpectedTokenException
  void parserUnexpectedToken(TokenType type) =>
      throw UnexpectedTokenException(
          '[Line ${lexer.lineNum}] Unexpected token `${curToken.value}`, was expecting `$type`');

  /// Sets the ast to be a child of a class
  ASTNode asClassChild(ASTNode ast, ASTNode object) {
    ast.isClassChild = true;
    ast.parent = object;
    return ast;
  }

  /// Check if the token is a DataType
  bool isDataType() {
    final String tokenValue = curToken.value;

    final List dataTypes = [
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

    final int lineNum = lexer.lineNum;
    final int curIndex = lexer.currentIndex;
    final String curChar = lexer.currentChar;

    final bool isDot = lexer.getNextToken().type == TokenType.TOKEN_DOT;

    lexer
      ..lineNum = lineNum
      ..currentIndex = curIndex
      ..currentChar = curChar;

    for (final String type in dataTypes) {
      if (!isDot && type == tokenValue || type + '?' == tokenValue)
        return true;
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
  ASTNode parseOneStatementCompound(Scope scope) {
    final compound = initASTWithLine(CompoundNode(), lexer.lineNum);
    compound.scope = scope;

    final statement = parseStatement(scope);
    compound.compoundValue.add(statement);

    return compound;
  }

  ASTNode parse({Scope scope}) {
    return parseStatements(scope);
  }

  void eat(TokenType type) {
    if (curToken.type != type) {
      parserUnexpectedToken(type);
    } else {
      prevToken = curToken;
      curToken = lexer.getNextToken();
    }
  }

  ASTNode parseStatement(Scope scope) {
    switch (curToken.type) {
      case TokenType.TOKEN_ID:
        {
          final tokenValue = curToken.value;

          if (isModifier(tokenValue)) {
            eat(TokenType.TOKEN_ID);
            if (tokenValue == FINAL)
              return parseDefinition(scope, false, true);

            return parseDefinition(scope, true);
          }

          if (isDataType()) {
            return parseDefinition(scope);
          }

          switch (tokenValue) {
            case WHILE:
              return parseWhile(scope);
            case FOR:
              return parseFor(scope);
            case IF:
              return parseIf(scope);
            case SWITCH:
              return parseSwitch(scope);
            case FALSE:
            case TRUE:
              return parseBool(scope);
            case NULL:
              return parseNull(scope);
            case RETURN:
              return parseReturn(scope);
            case THROW:
              return parseThrow(scope);
            case BREAK:
              return parseBreak(scope);
            case NEXT:
              return parseNext(scope);
            case NEW:
              return parseNew(scope);
            case ITERATE:
              return parseIterate(scope);
            case ASSERT:
              return parseAssert(scope);
          }

          eat(TokenType.TOKEN_ID);

          var a = parseVariable(scope);

          while (curToken.type == TokenType.TOKEN_LPAREN) {
            a = parseFunctionCall(scope, a);
          }

          while (curToken.type == TokenType.TOKEN_DOT) {
            eat(TokenType.TOKEN_DOT);

            final ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum)..binaryOpLeft = a;

            eat(TokenType.TOKEN_ID);

            final varAST = parseVariable(scope);

            ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
                ? parseFunctionCall(scope, varAST)
                : varAST;
            a = ast;
          }

          while (curToken.type == TokenType.TOKEN_LBRACKET) {
            final astListAccess = initASTWithLine(ListAccessNode(), lexer.lineNum);
            astListAccess.binaryOpLeft = a;
            eat(TokenType.TOKEN_LBRACKET);

            astListAccess.listAccessPointer = parseExpression(scope);

            eat(TokenType.TOKEN_RBRACKET);

            a = astListAccess;
          }

          if (a != null)
            return a;
        }
        break;
      case TokenType.TOKEN_LESS_THAN:
        eat(TokenType.TOKEN_LESS_THAN);

        final String annotation = curToken.value;
        eat(TokenType.TOKEN_ID);

        eat(TokenType.TOKEN_GREATER_THAN);

        switch (annotation) {
          case SUPERSEDE:
            return parseDefinition(
                scope,
                curToken.value == 'const',
                curToken.value == 'final',
                true);
          default:
            throw UnexpectedTokenException(
                'No annotation ${curToken.value} found!');
        }
        break;
      case TokenType.TOKEN_NUMBER_VALUE:
      case TokenType.TOKEN_STRING_VALUE:
      case TokenType.TOKEN_DOUBLE_VALUE:
      case TokenType.TOKEN_INT_VALUE:
        return parseExpression(scope);
      case TokenType.TOKEN_PLUS_PLUS:
      case TokenType.TOKEN_SUB_SUB:
      case TokenType.TOKEN_MUL_MUL:
        {
          final Token operator = curToken;
          eat(operator.type);

          final ASTNode astVarMod = initASTWithLine(VarModNode(), lexer.lineNum)
            ..binaryOpRight = parseStatement(scope)
            ..binaryOperator = operator
            ..scope = scope;

          return astVarMod;
        }
        break;
      case TokenType.TOKEN_LBRACE:
        final int lineNum = lexer.lineNum;
        while (curToken.type != TokenType.TOKEN_RBRACE) {
          if (lexer.currentIndex == lexer.program.length)
            throw UnexpectedTokenException('[Lines $lineNum-${lexer.lineNum}] No closing brace `}` was found');
          eat(curToken.type);
        }
        eat(TokenType.TOKEN_RBRACE);

        return initASTWithLine(NoopNode(), lineNum);

      case TokenType.TOKEN_LBRACKET:
        return parseList(scope);

      default:
        return initASTWithLine(NoopNode(), lexer.lineNum);
    }

    return initASTWithLine(NoopNode(), lexer.lineNum);
  }

  ASTNode parseStatements(Scope scope) {
    final compound = initASTWithLine(CompoundNode(), lexer.lineNum);
    compound.scope = scope;

    ASTNode statement = parseStatement(scope);

    compound.compoundValue.add(statement);

    while (curToken.type == TokenType.TOKEN_SEMI ||
        prevToken?.type == TokenType.TOKEN_RBRACE &&
            statement.type != ASTType.AST_NOOP) {
      if (curToken.type == TokenType.TOKEN_SEMI)
        eat(TokenType.TOKEN_SEMI);

      statement = parseStatement(scope);

      compound.compoundValue.add(statement);
    }

    if (curToken.type != TokenType.TOKEN_RBRACE &&
        lexer.currentIndex != lexer.program.length)
      throw UnexpectedTokenException(
          'Error [Line ${lexer.lineNum}]: Expected `;` but found `${curToken.value}`');

    return compound;
  }

  ASTNode parseType(Scope scope) {
    final ASTNode astType = initASTWithLine(TypeNode(), lexer.lineNum)
      ..scope = scope;

    final type = DataType();

    var tokenValue = curToken.value;

    if (tokenValue.endsWith('?'))
      tokenValue =
          tokenValue.replaceRange(tokenValue.length - 1, tokenValue.length, '');

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

    eat(TokenType.TOKEN_ID);

    return astType;
  }

  ASTNode parseDouble(Scope scope) {
    final ast = initASTWithLine(DoubleNode(), lexer.lineNum);
    ast.scope = scope;
    ast.doubleVal = double.parse(curToken.value);

    eat(TokenType.TOKEN_DOUBLE_VALUE);

    return ast;
  }

  ASTNode parseString(Scope scope) {
    final ast = initASTWithLine(StringNode(), lexer.lineNum)
      ..scope = scope
      ..stringValue = curToken.value;

    eat(TokenType.TOKEN_STRING_VALUE);

    return ast;
  }

  ASTNode parseInt(Scope scope) {
    final ast = initASTWithLine(IntNode(), lexer.lineNum)
      ..scope = scope
      ..intVal = int.tryParse(curToken.value);

    eat(TokenType.TOKEN_INT_VALUE);

    return ast;
  }

  ASTNode parseBool(Scope scope) {
    final ast = initASTWithLine(BoolNode(), lexer.lineNum)..scope = scope;

    if (curToken.value == 'false' || curToken.value == 'true') {
      ast.boolVal = curToken.value == 'true';
    } else {
      print('Expected a boolean value, but got ${curToken.value}');
    }

    eat(TokenType.TOKEN_ID);

    return ast;
  }

  ASTNode parseNull(Scope scope) {
    final ast = initASTWithLine(NoSeebNode(), lexer.lineNum)..scope = scope;

    eat(TokenType.TOKEN_ID);

    return ast;
  }

  ASTNode parseVariable(Scope scope) {
    final ast = initASTWithLine(VariableNode(), lexer.lineNum)
      ..scope = scope
      ..variableName = prevToken.value;

    if (curToken.type == TokenType.TOKEN_RBRACE) {
      final astAssign = initASTWithLine(VarAssignmentNode(), lexer.lineNum)
        ..variableAssignmentLeft = ast
        ..variableValue = parseExpression(scope)
        ..scope = scope;

      return astAssign;
    }

    if (curToken.type == TokenType.TOKEN_EQUAL) {
      eat(TokenType.TOKEN_EQUAL);
      final astAssign = initASTWithLine(VarAssignmentNode(), lexer.lineNum);
      astAssign.variableAssignmentLeft = ast;
      astAssign.variableValue = parseExpression(scope);
      astAssign.scope = scope;

      return astAssign;
    }
    if (curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        curToken.type == TokenType.TOKEN_SUB_SUB ||
        curToken.type == TokenType.TOKEN_MUL_MUL) {
      final Token operator = curToken;

      eat(operator.type);

      final ASTNode astVarMod = initASTWithLine(VarModNode(), lexer.lineNum)
        ..binaryOpLeft = ast
        ..binaryOperator = operator
        ..scope = scope;

      return astVarMod;
    } else if (curToken.type == TokenType.TOKEN_PLUS_EQUAL ||
        curToken.type == TokenType.TOKEN_SUB_EQUAL ||
        curToken.type == TokenType.TOKEN_MUL_EQUAL ||
        curToken.type == TokenType.TOKEN_DIV_EQUAL ||
        curToken.type == TokenType.TOKEN_MOD_EQUAL ||
        curToken.type == TokenType.TOKEN_NOSEEB_ASSIGNMENT) {
      final Token operator = curToken;

      eat(operator.type);

      final ASTNode astVarMod = initASTWithLine(VarModNode(), lexer.lineNum)
        ..binaryOpLeft = ast
        ..binaryOpRight = parseExpression(scope)
        ..binaryOperator = operator
        ..scope = scope;

      return astVarMod;
    }

    return ast;
  }

  ASTNode parseBrace(Scope scope) {
    if (prevToken.type != TokenType.TOKEN_ID)
      return parseMap(scope);

    return parseClass(scope);
  }

  ASTNode parseClass(Scope scope) {
    final ASTNode ast = initASTWithLine(ClassNode(), lexer.lineNum)
      ..scope = scope
      ..className = prevToken.value
      ..classChildren = ListQueue();

    final newScope = Scope(false);

    if (scope != null && scope.owner != null)
      newScope.owner = scope.owner;

    eat(TokenType.TOKEN_LBRACE);

    if (curToken.type != TokenType.TOKEN_RBRACE) {
      if (curToken.type == TokenType.TOKEN_ID ||
          curToken.type == TokenType.TOKEN_LESS_THAN) {
        ast.classChildren
            .add(asClassChild(parseDefinition(newScope), ast));
      }

      while (curToken.type == TokenType.TOKEN_SEMI ||
          (prevToken.type == TokenType.TOKEN_RBRACE &&
              curToken.type != TokenType.TOKEN_RBRACE)) {
        if (curToken.type == TokenType.TOKEN_SEMI)
          eat(TokenType.TOKEN_SEMI);

        if (curToken.type == TokenType.TOKEN_ID ||
            curToken.type == TokenType.TOKEN_LESS_THAN) {
          ast.classChildren
              .add(asClassChild(parseDefinition(newScope), ast));
        }
      }
    }

    eat(TokenType.TOKEN_RBRACE);

    return ast;
  }

  ASTNode parseEnum(Scope scope) {
    final ast = initASTWithLine(EnumNode(), lexer.lineNum);
    ast.scope = scope;
    ast.enumElements = [];

    final newScope = Scope(false);

    if (scope != null) {
      if (scope.owner != null) {
        newScope.owner = scope.owner;
      }
    }

    eat(TokenType.TOKEN_LBRACE);

    if (curToken.type != TokenType.TOKEN_RBRACE) {
      if (curToken.type == TokenType.TOKEN_ID) {
        eat(TokenType.TOKEN_ID);
        ast.enumElements.add(parseVariable(newScope));
      }

      while (curToken.type == TokenType.TOKEN_COMMA) {
        eat(TokenType.TOKEN_COMMA);

        if (curToken.type == TokenType.TOKEN_ID) {
          eat(TokenType.TOKEN_ID);
          ast.enumElements.add(parseVariable(newScope));
        }
      }
    }

    eat(TokenType.TOKEN_RBRACE);

    return ast;
  }

  ASTNode parseMap(Scope scope) {
    eat(TokenType.TOKEN_LBRACE);

    final ast = initASTWithLine(MapNode(), lexer.lineNum);
    ast.scope = scope;
    ast.map = {};

    if (curToken.type != TokenType.TOKEN_RBRACE) {
      if (curToken.type == TokenType.TOKEN_STRING_VALUE) {
        final String key = curToken.value;
        eat(TokenType.TOKEN_STRING_VALUE);

        if (curToken.type == TokenType.TOKEN_COLON)
          eat(TokenType.TOKEN_COLON);
        else
          throw UnexpectedTokenException(
              'Error: [Line ${lexer.lineNum}] Unexpected token `${curToken.value}`, expected `:`.');

        if (curToken.type == TokenType.TOKEN_COMMA)
          throw UnexpectedTokenException(
              'Error: [Line ${lexer.lineNum}] Expected value for key `$key`');
        ast.map[key] = parseExpression(scope);
      } else
        throw UnexpectedTokenException(
            'Error: [Line ${lexer.lineNum}] Maps can only hold strings as keys.');
    }

    while (curToken.type == TokenType.TOKEN_COMMA) {
      eat(TokenType.TOKEN_COMMA);

      final String key = curToken.value;
      eat(TokenType.TOKEN_STRING_VALUE);

      if (curToken.type == TokenType.TOKEN_COLON)
        eat(TokenType.TOKEN_COLON);
      else
        throw UnexpectedTokenException(
            'Error: [Line ${lexer.lineNum}] Unexpected token `${curToken.value}`, expected `:`.');

      if (curToken.type == TokenType.TOKEN_COMMA)
        throw UnexpectedTokenException(
            'Error: [Line ${lexer.lineNum}] Expected value for key `$key`');

      ast.map[key] = parseExpression(scope);
    }

    eat(TokenType.TOKEN_RBRACE);
    return ast;
  }

  ASTNode parseList(Scope scope) {
    eat(TokenType.TOKEN_LBRACKET);
    final ast = initASTWithLine(ListNode(), lexer.lineNum);
    ast.scope = scope;
    ast.listElements = [];

    if (curToken.type != TokenType.TOKEN_RBRACKET) {
      ast.listElements.add(parseExpression(scope));
    }

    while (curToken.type == TokenType.TOKEN_COMMA) {
      eat(TokenType.TOKEN_COMMA);
      ast.listElements.add(parseExpression(scope));
    }

    eat(TokenType.TOKEN_RBRACKET);
    return ast;
  }

  ASTNode parseFactor(Scope scope, bool isMap) {
    while (curToken.type == TokenType.TOKEN_PLUS ||
        curToken.type == TokenType.TOKEN_SUB ||
        curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        curToken.type == TokenType.TOKEN_SUB_SUB ||
        curToken.type == TokenType.TOKEN_NOT ||
        curToken.type == TokenType.TOKEN_ONES_COMPLEMENT) {
      final unOpOperator = curToken;
      eat(unOpOperator.type);

      final ast = initASTWithLine(UnaryOpNode(), lexer.lineNum);
      ast.scope = scope;
      ast.unaryOperator = unOpOperator;
      ast.unaryOpRight = parseTerm(scope);

      return ast;
    }

    if (curToken.type == TokenType.TOKEN_ID) {
      switch (curToken.value) {
        case TRUE:
        case FALSE:
          return parseBool(scope);
        case NULL:
          return parseNull(scope);
        case NEW:
          return parseNew(scope);
      }
    }

    if (curToken.type == TokenType.TOKEN_PLUS ||
        curToken.type == TokenType.TOKEN_SUB ||
        curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        curToken.type == TokenType.TOKEN_SUB_SUB ||
        curToken.type == TokenType.TOKEN_NOT ||
        curToken.type == TokenType.TOKEN_BITWISE_AND ||
        curToken.type == TokenType.TOKEN_BITWISE_OR ||
        curToken.type == TokenType.TOKEN_BITWISE_XOR ||
        curToken.type == TokenType.NOSEEB_AWARE_OPERATOR ||
        curToken.type == TokenType.TOKEN_LSHIFT ||
        curToken.type == TokenType.TOKEN_RSHIFT) {
      eat(curToken.type);

      var a = parseVariable(scope).binaryOpRight;

      while (curToken.type == TokenType.TOKEN_DOT) {
        eat(TokenType.TOKEN_DOT);
        final ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum);
        ast.binaryOpLeft = a;
        eat(TokenType.TOKEN_ID);
        final varAST = parseVariable(scope);
        ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
            ? parseFunctionCall(scope, varAST)
            : varAST;
        a = ast;
      }

      while (curToken.type == TokenType.TOKEN_DOT) {
        eat(TokenType.TOKEN_DOT);
        final ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum);
        ast.binaryOpLeft = a;
        eat(TokenType.TOKEN_ID);
        final varAST = parseVariable(scope);
        ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
            ? parseFunctionCall(scope, varAST)
            : varAST;
        a = ast;
      }

      while (curToken.type == TokenType.TOKEN_LBRACKET) {
        final astListAccess =
        initASTWithLine(ListAccessNode(), lexer.lineNum);
        astListAccess.binaryOpLeft = a;

        eat(TokenType.TOKEN_LBRACKET);
        astListAccess.listAccessPointer = parseExpression(scope);
        eat(TokenType.TOKEN_RBRACKET);

        a = astListAccess;
      }

      while (curToken.type == TokenType.TOKEN_LPAREN)
        a = parseFunctionCall(scope, a);

      if (a != null)
        return a;
    }

    if (curToken.type == TokenType.TOKEN_ID) {
      eat(curToken.type);

      var a = parseVariable(scope);

      while (curToken.type == TokenType.TOKEN_DOT) {
        eat(TokenType.TOKEN_DOT);
        final ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum);
        ast.binaryOpLeft = a;
        eat(TokenType.TOKEN_ID);
        final varAST = parseVariable(scope);
        ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
            ? parseFunctionCall(scope, varAST)
            : varAST;
        a = ast;
      }

      while (curToken.type == TokenType.TOKEN_LBRACKET) {
        final astListAccess =
        initASTWithLine(ListAccessNode(), lexer.lineNum);
        astListAccess.binaryOpLeft = a;

        eat(TokenType.TOKEN_LBRACKET);
        astListAccess.listAccessPointer = parseExpression(scope);
        eat(TokenType.TOKEN_RBRACKET);

        a = astListAccess;
      }

      while (curToken.type == TokenType.TOKEN_LPAREN)
        a = parseFunctionCall(scope, a);

      if (a != null)
        return a;
    }

    /* */
    if (curToken.type == TokenType.TOKEN_LPAREN) {
      eat(TokenType.TOKEN_LPAREN);
      final astExpression = parseExpression(scope);
      eat(TokenType.TOKEN_RPAREN);

      return astExpression;
    }

    switch (curToken.type) {
      case TokenType.TOKEN_NUMBER_VALUE:
      case TokenType.TOKEN_INT_VALUE:
        return parseInt(scope);
      case TokenType.TOKEN_DOUBLE_VALUE:
        return parseDouble(scope);
      case TokenType.TOKEN_STRING_VALUE:
        return parseString(scope);
      case TokenType.TOKEN_LBRACE:
        return parseBrace(scope);
      case TokenType.TOKEN_LBRACKET:
        return parseList(scope);
      default:
        throw UnexpectedTokenException('Unexpected ${curToken.value}');
        break;
    }
  }

  ASTNode parseTerm(Scope scope, {bool isFuncDefArgs = false}) {
    final tokenValue = curToken.value;

    if (isModifier(tokenValue)) {
      eat(TokenType.TOKEN_ID);
      if (tokenValue == FINAL)
        return parseDefinition(scope, false, true, false, true);

      return parseDefinition(scope, true, false, false, true);
    }

    if (isDataType())
      return parseDefinition(scope, false, false, false, true);

    var node = parseFactor(scope, false);
    ASTNode astBinaryOp;

    if (curToken.type == TokenType.TOKEN_LPAREN)
      node = parseFunctionCall(scope, node);

    while (curToken.type == TokenType.TOKEN_DIV ||
        curToken.type == TokenType.TOKEN_MUL ||
        curToken.type == TokenType.TOKEN_LESS_THAN ||
        curToken.type == TokenType.TOKEN_GREATER_THAN ||
        curToken.type == TokenType.TOKEN_LESS_THAN_EQUAL ||
        curToken.type == TokenType.TOKEN_GREATER_THAN_EQUAL ||
        curToken.type == TokenType.TOKEN_EQUALITY ||
        curToken.type == TokenType.TOKEN_NOT_EQUAL) {
      final binaryOpOperator = curToken;
      eat(binaryOpOperator.type);

      astBinaryOp = initASTWithLine(BinaryOpNode(), lexer.lineNum);

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOpOperator;
      astBinaryOp.binaryOpRight = parseFactor(scope, false);

      node = astBinaryOp;
    }
    return node;
  }

  ASTNode parseExpression(Scope scope,
      {bool isFuncDefArgs = false}) {
    var node = parseTerm(scope, isFuncDefArgs: isFuncDefArgs);
    ASTNode astBinaryOp;

    while (curToken.type == TokenType.TOKEN_PLUS ||
        curToken.type == TokenType.TOKEN_SUB ||
        curToken.type == TokenType.TOKEN_PLUS_PLUS ||
        curToken.type == TokenType.TOKEN_SUB_SUB ||
        curToken.type == TokenType.TOKEN_NOT ||
        curToken.type == TokenType.TOKEN_BITWISE_AND ||
        curToken.type == TokenType.TOKEN_BITWISE_OR ||
        curToken.type == TokenType.TOKEN_BITWISE_XOR ||
        curToken.type == TokenType.TOKEN_LSHIFT ||
        curToken.type == TokenType.NOSEEB_AWARE_OPERATOR ||
        curToken.type == TokenType.TOKEN_RSHIFT) {
      if (curToken.type == TokenType.TOKEN_PLUS_PLUS ||
          curToken.type == TokenType.TOKEN_SUB_SUB) {
        final binaryOp = curToken;
        eat(binaryOp.type);

        astBinaryOp = initASTWithLine(BinaryOpNode(), lexer.lineNum);
        astBinaryOp.scope = scope;

        astBinaryOp.binaryOpLeft = node;
        astBinaryOp.binaryOperator = binaryOp;
        astBinaryOp.binaryOpRight =
            parseTerm(scope, isFuncDefArgs: isFuncDefArgs);

        node = astBinaryOp;
      } else {
        final binaryOp = curToken;
        eat(binaryOp.type);

        astBinaryOp = initASTWithLine(BinaryOpNode(), lexer.lineNum);
        astBinaryOp.scope = scope;

        astBinaryOp.binaryOpLeft = node;
        astBinaryOp.binaryOperator = binaryOp;
        astBinaryOp.binaryOpRight =
            parseTerm(scope, isFuncDefArgs: isFuncDefArgs);

        node = astBinaryOp;
      }
    }

    while (curToken.type == TokenType.TOKEN_AND ||
        curToken.type == TokenType.TOKEN_OR) {
      final binaryOp = curToken;
      eat(binaryOp.type);

      astBinaryOp = initASTWithLine(BinaryOpNode(), lexer.lineNum);
      astBinaryOp.scope = scope;

      astBinaryOp.binaryOpLeft = node;
      astBinaryOp.binaryOperator = binaryOp;
      astBinaryOp.binaryOpRight = parseTerm(scope);

      node = astBinaryOp;
    }

    if (curToken.type == TokenType.TOKEN_QUESTION)
      return parseTernary(scope, node);

    return node;
  }

  ASTNode parseBreak(Scope scope) {
    eat(TokenType.TOKEN_ID);

    return initASTWithLine(BreakNode(), lexer.lineNum);
  }

  ASTNode parseNext(Scope scope) {
    eat(TokenType.TOKEN_ID);

    return initASTWithLine(NextNode(), lexer.lineNum);
  }

  ASTNode parseNew(Scope scope) {
    eat(TokenType.TOKEN_ID);

    final ASTNode newAST = initASTWithLine(NewNode(), lexer.lineNum)
      ..newValue = parseExpression(scope);

    return newAST;
  }

  ASTNode parseReturn(Scope scope) {
    eat(TokenType.TOKEN_ID);
    final ast = initASTWithLine(ReturnNode(), lexer.lineNum)
      ..scope = scope
      ..returnValue = parseExpression(scope) ?? NoSeebNode();

    return ast;
  }

  ASTNode parseThrow(Scope scope) {
    eat(TokenType.TOKEN_ID);
    final ast = initASTWithLine(ThrowNode(), lexer.lineNum)
      ..scope = scope
      ..throwValue = parseExpression(scope) ?? NoSeebNode();

    return ast;
  }

  ASTNode parseIf(Scope scope) {
    final ast = initASTWithLine(IfNode(), lexer.lineNum);
    eat(TokenType.TOKEN_ID);
    eat(TokenType.TOKEN_LPAREN);

    ast.ifExpression = parseExpression(scope);

    eat(TokenType.TOKEN_RPAREN);

    ast.scope = scope;

    if (curToken.type == TokenType.TOKEN_LBRACE) {
      eat(TokenType.TOKEN_LBRACE);
      ast.ifBody = parseStatements(scope);
      eat(TokenType.TOKEN_RBRACE);
    } else {
      ast.ifBody = parseOneStatementCompound(scope);
    }

    if (curToken.value == ELSE) {
      eat(TokenType.TOKEN_ID);

      if (curToken.value == IF) {
        ast.ifElse = parseIf(scope);
        ast.ifElse.scope = scope;
      } else {
        if (curToken.type == TokenType.TOKEN_LBRACE) {
          eat(TokenType.TOKEN_LBRACE);
          ast.elseBody = parseStatements(scope);
          ast.elseBody.scope = scope;
          eat(TokenType.TOKEN_RBRACE);
        } else {
          final compound = initASTWithLine(CompoundNode(), lexer.lineNum);
          compound.scope = scope;
          final statement = parseStatement(scope);
          eat(TokenType.TOKEN_SEMI);
          compound.compoundValue.add(statement);

          ast.elseBody = compound;
          ast.elseBody.scope = scope;
        }
      }
    }

    return ast;
  }

  ASTNode parseSwitch(Scope scope) {
    final ASTNode switchAST = initASTWithLine(SwitchNode(), lexer.lineNum)
      ..switchCases = {};

    eat(TokenType.TOKEN_ID);
    eat(TokenType.TOKEN_LPAREN);

    switchAST.switchExpression = parseExpression(scope);

    eat(TokenType.TOKEN_RPAREN);
    eat(TokenType.TOKEN_LBRACE);
    eat(TokenType.TOKEN_ID);

    ASTNode caseAST = parseStatement(scope);

    eat(TokenType.TOKEN_COLON);
    eat(TokenType.TOKEN_LBRACE);

    ASTNode caseFuncAST = parseStatements(scope);

    eat(TokenType.TOKEN_RBRACE);

    switchAST.switchCases[caseAST] = caseFuncAST;

    while (curToken.value == CASE) {
      eat(TokenType.TOKEN_ID);

      caseAST = parseStatement(scope);

      eat(TokenType.TOKEN_COLON);
      eat(TokenType.TOKEN_LBRACE);

      caseFuncAST = parseStatements(scope);

      eat(TokenType.TOKEN_RBRACE);

      switchAST.switchCases[caseAST] = caseFuncAST;
    }

    // Default case (REQUIRED)
    eat(TokenType.TOKEN_ID);
    eat(TokenType.TOKEN_COLON);
    eat(TokenType.TOKEN_LBRACE);

    final ASTNode defaultFuncAST = parseStatements(scope);

    eat(TokenType.TOKEN_RBRACE);

    switchAST.switchDefault = defaultFuncAST;

    eat(TokenType.TOKEN_RBRACE);

    return switchAST;
  }

  ASTNode parseTernary(Scope scope, ASTNode expr) {
    final ternary = initASTWithLine(TernaryNode(), lexer.lineNum);
    ternary.ternaryExpression = expr;

    eat(TokenType.TOKEN_QUESTION);

    ternary.ternaryBody = parseTerm(scope);

    eat(TokenType.TOKEN_COLON);

    ternary.ternaryElseBody = parseTerm(scope);

    return ternary;
  }

  ASTNode parseIterate(Scope scope) {
    eat(TokenType.TOKEN_ID);
    final astVar = parseExpression(scope);
    eat(TokenType.TOKEN_ID);

    ASTNode astFuncName;

    if (isModifier(curToken.value)) {
      eat(TokenType.TOKEN_ID);
      if (curToken.value == FINAL)
        return parseDefinition(scope, false, true);

      return parseDefinition(scope, true);
    }

    if (isDataType()) {
      astFuncName = parseDefinition(scope);
    } else {
      eat(TokenType.TOKEN_ID);
      astFuncName = parseVariable(scope);
    }

    final ast = initASTWithLine(IterateNode(), lexer.lineNum);
    ast.iterateIterable = astVar;
    ast.iterateFunction = astFuncName;

    return ast;
  }

  ASTNode parseAssert(Scope scope) {
    eat(TokenType.TOKEN_ID);
    final ast = initASTWithLine(AssertNode(), lexer.lineNum);
    ast.assertExpression = parseExpression(scope);

    return ast;
  }

  ASTNode parseWhile(Scope scope) {
    eat(TokenType.TOKEN_ID);
    eat(TokenType.TOKEN_LPAREN);
    final ast = initASTWithLine(WhileNode(), lexer.lineNum);
    ast.whileExpression = parseExpression(scope);
    eat(TokenType.TOKEN_RPAREN);

    if (curToken.type == TokenType.TOKEN_LBRACE) {
      eat(TokenType.TOKEN_LBRACE);
      ast.whileBody = parseStatements(scope);
      eat(TokenType.TOKEN_RBRACE);
      ast.scope = scope;
    } else {
      ast.whileBody = parseOneStatementCompound(scope);
      ast.whileBody.scope = scope;
    }

    return ast;
  }

  ASTNode parseFor(Scope scope) {
    final ast = ForNode();

    eat(TokenType.TOKEN_ID);
    eat(TokenType.TOKEN_LPAREN);

    ast.forInitStatement = parseStatement(scope);
    eat(TokenType.TOKEN_SEMI);

    ast.forConditionStatement = parseExpression(scope);
    eat(TokenType.TOKEN_SEMI);

    ast.forChangeStatement = parseStatement(scope);

    eat(TokenType.TOKEN_RPAREN);

    if (curToken.type == TokenType.TOKEN_LBRACE) {
      eat(TokenType.TOKEN_LBRACE);
      ast.forBody = parseStatements(scope);
      ast.forBody.scope = scope;
      eat(TokenType.TOKEN_RBRACE);
    } else {
      ast.forBody = parseOneStatementCompound(scope);
      ast.forBody.scope = scope;
    }

    return ast;
  }

  ASTNode parseFunctionCall(Scope scope, ASTNode expr) {
    final ast = initASTWithLine(FuncCallNode(), lexer.lineNum);
    ast.funcCallExpression = expr;
    eat(TokenType.TOKEN_LPAREN);

    ast.scope = scope;

    if (curToken.type != TokenType.TOKEN_RPAREN) {
      var astExpr = parseExpression(scope);

      while (curToken.type == TokenType.TOKEN_DOT) {
        eat(TokenType.TOKEN_DOT);
        final AttributeAccessNode ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum);
        ast.binaryOpLeft = astExpr;
        eat(TokenType.TOKEN_ID);
        final ASTNode varAST = parseVariable(scope);
        ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
            ? parseFunctionCall(scope, varAST)
            : varAST;
        astExpr = ast;
      }

      if (curToken.type == TokenType.TOKEN_COLON) {
        eat(TokenType.TOKEN_COLON);
        astExpr.variableValue = parseExpression(scope);

        ast.namedFunctionCallArgs.add(astExpr);
      }
      else {
        if (astExpr.type == ASTType.AST_FUNC_DEFINITION) {
          astExpr.scope = Scope(false);
        }

        ast.functionCallArgs.add(astExpr);
      }

      while (curToken.type == TokenType.TOKEN_COMMA) {
        eat(TokenType.TOKEN_COMMA);
        astExpr = parseExpression(scope);

        if (curToken.type == TokenType.TOKEN_COLON) {
          eat(TokenType.TOKEN_COLON);
          astExpr.variableValue = parseExpression(scope);

          ast.namedFunctionCallArgs.add(astExpr);
        }
        else {
          if (astExpr.type == ASTType.AST_FUNC_DEFINITION) {
            astExpr.scope = Scope(false);
          }

          ast.functionCallArgs.add(astExpr);
        }
      }
    }

    eat(TokenType.TOKEN_RPAREN);

    return ast;
  }

  ASTNode parseDefinition(Scope scope,
      [bool isConst = false,
        bool isFinal = false,
        bool isSuperseding = false,
        bool isFuncDefArgs = false]) {
    if (curToken.type == TokenType.TOKEN_LESS_THAN) {
      eat(TokenType.TOKEN_LESS_THAN);

      final String annotation = curToken.value;
      eat(TokenType.TOKEN_ID);

      eat(TokenType.TOKEN_GREATER_THAN);

      switch (annotation) {
        case SUPERSEDE:
          isConst = curToken.value == 'const';
          isFinal = curToken.value == 'final';
          isSuperseding = true;
          break;
        default:
          throw UnexpectedTokenException(
              'No annotation `${curToken.value}` found!');
      }
    }

    final bool isNullable = curToken.value.endsWith('?');

    // TODO(Calamity): refactor
    if (curToken.value == 'const') {
      isConst = true;
      eat(TokenType.TOKEN_ID);
    }

    final ASTNode astType = parseType(scope);

    dataType = astType.typeValue;

    String name;
    bool isEnum = false;

    // TODO(Calamity): refactor
    if (prevToken.value == 'StrBuffer' &&
        curToken.type == TokenType.TOKEN_LPAREN) {
      final strBuffer = parseStrBuffer(scope, isConst, isFinal);
      if (isNullable) {
        strBuffer.isNullable = true;
      } else if (!isFuncDefArgs && strBuffer.variableValue == null ||
          strBuffer.variableValue is NoSeebNode) {
        throw UnexpectedTypeException(
            'Error [Line: ${lexer.lineNum}]Non-nullable variables cannot be given a null value, add the `?` suffix to a variable type to make it nullable');
      }

      return strBuffer;
    }

    if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM) {
      name = curToken.value;

      if (curToken.type == TokenType.TOKEN_ID)
        eat(TokenType.TOKEN_ID);
      else
        eat(TokenType.TOKEN_ANON_ID);
    } else
      isEnum = true;

    // Function Definition
    if (curToken.type == TokenType.TOKEN_LPAREN) {
      return parseFunctionDefinition(scope, name, astType);
    } else {
      final varDef = parseVariableDefinition(
          scope, name, astType, isEnum, isConst, isFinal, isSuperseding);

      if (isNullable) {
        varDef.isNullable = true;
      } else if (!isFuncDefArgs && varDef.variableValue == null ||
          varDef.variableValue is NoSeebNode) {
        throw UnexpectedTypeException(
            'Error [Line ${lexer.lineNum}]: Non-nullable variables cannot be given a null value, add the `?` suffix to a variable type to make it nullable');
      }

      return varDef;
    }
  }

  ASTNode parseFunctionDefinition(
      Scope scope, String funcName, ASTNode astType) {
    final ast = initASTWithLine(FuncDefNode(), lexer.lineNum)
      ..funcName = funcName
      ..funcDefType = astType
      ..functionDefArgs = [];

    final newScope = Scope(false)..owner = ast;

    eat(TokenType.TOKEN_LPAREN);

    if (curToken.type != TokenType.TOKEN_RPAREN) {

      if (curToken.type == TokenType.TOKEN_LBRACE) {
        eat(TokenType.TOKEN_LBRACE);
        ast.namedFunctionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));

        while (curToken.type != TokenType.TOKEN_RBRACE) {
          eat(TokenType.TOKEN_COMMA);
          ast.namedFunctionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));
        }
        eat(TokenType.TOKEN_RBRACE);
      }
      else
        ast.functionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));

      while (curToken.type == TokenType.TOKEN_COMMA) {
        eat(TokenType.TOKEN_COMMA);

        // Named parameters
        if (curToken.type == TokenType.TOKEN_LBRACE) {
          eat(TokenType.TOKEN_LBRACE);
          ast.namedFunctionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));

          while (curToken.type != TokenType.TOKEN_RBRACE) {
            eat(TokenType.TOKEN_COMMA);
            ast.namedFunctionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));
          }
          eat(TokenType.TOKEN_RBRACE);
        } else {
          ast.functionDefArgs.add(parseExpression(scope, isFuncDefArgs: true));
        }

      }
    }

    eat(TokenType.TOKEN_RPAREN);

    if (curToken.type == TokenType.TOKEN_INLINE) {
      eat(TokenType.TOKEN_INLINE);
      ast.functionDefBody = parseOneStatementCompound(newScope);
      ast.functionDefBody.scope = newScope;

      return ast;
    }

    if (curToken.type == TokenType.TOKEN_RBRACE) {
      ASTNode childDef;

      if (isModifier(curToken.value)) {
        eat(TokenType.TOKEN_ID);
        if (curToken.value == FINAL)
          return parseDefinition(scope, false, true);

        return parseDefinition(scope, true);
      }
      if (isDataType()) {
        childDef = parseDefinition(scope);
      } else {
        eat(TokenType.TOKEN_ID);
        childDef = parseVariable(scope);
      }

      childDef.scope = newScope;
      ast.compChildren.add(childDef);

      while (curToken.type == TokenType.TOKEN_COMMA) {
        eat(TokenType.TOKEN_COMMA);

        if (isModifier(curToken.value)) {
          eat(TokenType.TOKEN_ID);
          if (curToken.value == FINAL)
            return parseDefinition(scope, false, true);

          return parseDefinition(scope, true);
        }

        if (isDataType()) {
          childDef = parseDefinition(scope);
        } else {
          eat(TokenType.TOKEN_ID);
          childDef = parseVariable(scope);
        }

        childDef.scope = newScope;
        ast.compChildren.add(childDef);
      }
      return ast;
    }

    if (curToken.type == TokenType.TOKEN_EQUAL) {
      eat(TokenType.TOKEN_EQUAL);

      ASTNode childDef;

      if (isModifier(curToken.value)) {
        eat(TokenType.TOKEN_ID);
        if (curToken.value == FINAL)
          return parseDefinition(scope, false, true);

        return parseDefinition(scope, true);
      }

      if (isDataType()) {
        childDef = parseDefinition(scope);
      } else {
        eat(TokenType.TOKEN_ID);
        childDef = parseVariable(scope);
      }

      childDef.scope = newScope;
      ast.compChildren.add(childDef);

      while (curToken.type == TokenType.TOKEN_COMMA) {
        eat(TokenType.TOKEN_COMMA);

        if (isModifier(curToken.value)) {
          eat(TokenType.TOKEN_ID);
          if (curToken.value == FINAL)
            return parseDefinition(scope, false, true);

          return parseDefinition(scope, true);
        }

        if (isDataType()) {
          childDef = parseDefinition(scope);
        } else {
          eat(TokenType.TOKEN_ID);
          childDef = parseVariable(scope);
        }

        childDef.scope = newScope;
        ast.compChildren.add(childDef);
      }
      return ast;
    }
    eat(TokenType.TOKEN_LBRACE);
    ast.functionDefBody = parseStatements(newScope);
    ast.functionDefBody.scope = newScope;
    eat(TokenType.TOKEN_RBRACE);

    return ast;
  }

  ASTNode parseVariableDefinition(
      Scope scope, String name, ASTNode astType,
      [bool isEnum = false,
        bool isConst = false,
        bool isFinal = false,
        bool isSuperseding = false]) {
    final astVarDef = initASTWithLine(VarDefNode(), lexer.lineNum)
      ..scope = scope
      ..variableName = name
      ..variableType = astType
      ..isFinal = isFinal
      ..isSuperseding = isSuperseding;

    if (isEnum) {
      final astType = initASTWithLine(TypeNode(), lexer.lineNum);
      astType.scope = scope;

      final type = DataType()..type = DATATYPE.DATA_TYPE_ENUM;
      astType.typeValue = type;

      astVarDef.variableType = astType;
      astVarDef.variableValue = parseEnum(scope);
      astVarDef.variableName = curToken.value;
      eat(TokenType.TOKEN_ID);
    }

    if (curToken.value == 'follows') {
      eat(TokenType.TOKEN_ID);

      final VariableNode superClass =
      initASTWithLine(VariableNode(), lexer.lineNum)
        ..scope = scope
        ..variableName = curToken.value;

      eat(TokenType.TOKEN_ID);

      astVarDef.variableValue = parseClass(scope);
      astVarDef.variableValue.superClass = superClass;

      return astVarDef;
    }

    // Class
    if (curToken.type == TokenType.TOKEN_LBRACE) {
      astVarDef.variableValue = parseExpression(scope);

      switch (astVarDef.variableValue.type) {
        case ASTType.AST_CLASS:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_CLASS)
            parserTypeError();
          break;
        case ASTType.AST_ENUM:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_ENUM)
            parserTypeError();
          break;
        case ASTType.AST_COMPOUND:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_SOURCE)
            parserTypeError();
          break;
        default:
          break;
      }
    }

    if (curToken.type == TokenType.TOKEN_EQUAL) {
      if (isEnum)
        parserSyntaxError();

      eat(TokenType.TOKEN_EQUAL);

      astVarDef.variableValue = parseExpression(scope);

      while (curToken.type == TokenType.TOKEN_DOT) {
        eat(TokenType.TOKEN_DOT);
        final ast = initASTWithLine(AttributeAccessNode(), lexer.lineNum);
        ast.binaryOpLeft = astVarDef.variableValue;
        eat(TokenType.TOKEN_ID);
        final varAST = parseVariable(scope);
        ast.binaryOpRight = curToken.type == TokenType.TOKEN_LPAREN
            ? parseFunctionCall(scope, varAST)
            : varAST;
        astVarDef.variableValue = ast;
      }

      switch (astVarDef.variableValue.type) {
        case ASTType.AST_STRING:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_STRING;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program.replaceAll(
                  RegExp('[^"\'](?:${astVarDef.parent.className})?$name[^"\']'),
                  astVarDef.variableValue.stringValue);
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING)
            parserTypeError();
          break;
        case ASTType.AST_STRING_BUFFER:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_STRING_BUFFER;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program.replaceAll(name,
                  astVarDef.variableValue.strBuffer.toString());
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_STRING_BUFFER)
            parserTypeError();
          break;
        case ASTType.AST_INT:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_INT;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program
                  .replaceAll(name, '${astVarDef.variableValue.intVal}');
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_INT)
            parserTypeError();
          break;
        case ASTType.AST_DOUBLE:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_DOUBLE;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program
                  .replaceAll(name, '${astVarDef.variableValue.doubleVal}');
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_DOUBLE)
            parserTypeError();
          break;
        case ASTType.AST_BOOL:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_BOOL;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program
                  .replaceAll(name, '${astVarDef.variableValue.boolVal}');
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_BOOL)
            parserTypeError();
          break;
        case ASTType.AST_LIST:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_LIST;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program
                  .replaceAll(name, '${astVarDef.variableValue.listElements}');
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_LIST)
            parserTypeError();
          break;
        case ASTType.AST_MAP:
          if (astType.typeValue.type == DATATYPE.DATA_TYPE_VAR) {
            astType.typeValue.type = DATATYPE.DATA_TYPE_MAP;
            astVarDef.variableType = astType;
            if (isConst)
              lexer.program = lexer.program
                  .replaceAll(name, '${astVarDef.variableValue.map}');
          }
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_MAP)
            parserTypeError();
          break;
        case ASTType.AST_COMPOUND:
          if (astType.typeValue.type != DATATYPE.DATA_TYPE_SOURCE)
            parserTypeError();
          break;
        default:
          break;
      }
    }

    return astVarDef;
  }

  ASTNode parseStrBuffer(Scope scope,
      [bool isConst = false, bool isFinal = false]) {
    eat(TokenType.TOKEN_LPAREN);
    final ASTNode strBufferAST = initASTWithLine(StrBufferNode(), lexer.lineNum)
      ..strBuffer = StringBuffer(curToken.value)
      ..isFinal = isFinal;

    eat(TokenType.TOKEN_STRING_VALUE);
    eat(TokenType.TOKEN_RPAREN);

    return strBufferAST;
  }

}
