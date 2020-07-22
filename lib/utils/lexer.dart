import 'dart:io';

import 'token.dart';

class Lexer {
  String contents;
  String currentChar;

  int currentIndex;
  int lineNum;
}

Lexer initLexer(String contents) {
  var lexer = Lexer();
  lexer.contents = contents.trim();
  lexer.currentIndex = 0;
  lexer.lineNum = 1;
  lexer.currentChar = lexer.contents[lexer.currentIndex];

  return lexer;
}

Token getNextToken(Lexer lexer) {
  while (
      lexer.currentIndex < lexer.contents.length && lexer.currentChar != null) {
    if (lexer.currentChar == ' ' ||
        lexer.currentChar == '\n' ||
        lexer.currentChar == '\r') skipWhitespace(lexer);

    if (isNumeric(lexer.currentChar)) {
      return collectNumber(lexer);
    }

    if (RegExp('[a-zA-Z0-9]').hasMatch(lexer.currentChar)) {
      return collectId(lexer);
    }

    if (lexer.currentChar == '+') {
      var value = curString(lexer);
      var type = TokenType.TOKEN_PLUS;

      advance(lexer);

      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_PLUS_EQUAL;
        value += curString(lexer);

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '-') {
      var value = curString(lexer);
      var type = TokenType.TOKEN_SUB;

      advance(lexer);

      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_SUB_EQUAL;
        value += curString(lexer);

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '*') {
      var value = curString(lexer);
      var type = TokenType.TOKEN_MUL;

      advance(lexer);

      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_MUL_EQUAL;
        value += curString(lexer);

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '&') {
      var value = curString(lexer);

      advance(lexer);

      if (lexer.currentChar == '&') {
        value += curString(lexer);

        advance(lexer);

        return initToken(TokenType.TOKEN_AND, value);
      }
    }

    if (lexer.currentChar == '|') {
      var value = curString(lexer);

      advance(lexer);

      if (lexer.currentChar == '|') {
        value += curString(lexer);

        advance(lexer);

        return initToken(TokenType.TOKEN_OR, value);
      }
    }

    if (lexer.currentChar == '=') {
      var value = curString(lexer);
      var type = TokenType.TOKEN_EQUAL;

      advance(lexer);

      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_EQUALITY;
        value += curString(lexer);

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '!') {
      var value = curString(lexer);
      var type = TokenType.TOKEN_NOT;

      advance(lexer);

      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_NOT_EQUAL;
        value += curString(lexer);

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '/') {
      advance(lexer);

      if (lexer.currentChar == '/') {
        advance(lexer);
        skipInlineComment(lexer);
        continue;
      } else if (lexer.currentChar == '*') {
        advance(lexer);
        skipBlockComment(lexer);
        continue;
      } else {
        return initToken(TokenType.TOKEN_DIV, '/');
      }
    }

    if (lexer.currentChar == '' || lexer.currentChar == null) {
      return initToken(TokenType.TOKEN_EOF, '');
    }

    switch (lexer.currentChar) {
      case '"':
        return collectString(lexer);
      case '\'':
        return collectSingleQuoteString(lexer);
      case '{':
        return advanceWithToken(lexer, TokenType.TOKEN_LBRACE);
      case '}':
        return advanceWithToken(lexer, TokenType.TOKEN_RBRACE);
      case '(':
        return advanceWithToken(lexer, TokenType.TOKEN_LPARAN);
      case ')':
        return advanceWithToken(lexer, TokenType.TOKEN_RPARAN);
      case '[':
        return advanceWithToken(lexer, TokenType.TOKEN_LBRACKET);
      case ']':
        return advanceWithToken(lexer, TokenType.TOKEN_RBRACKET);
      case ';':
        return advanceWithToken(lexer, TokenType.TOKEN_SEMI);
      case ',':
        return advanceWithToken(lexer, TokenType.TOKEN_COMMA);
      case '.':
        return advanceWithToken(lexer, TokenType.TOKEN_DOT);
      case '%':
        return advanceWithToken(lexer, TokenType.TOKEN_MOD);
      case '<':
        return advanceWithToken(lexer, TokenType.TOKEN_LESS_THAN);
      case '>':
        return advanceWithToken(lexer, TokenType.TOKEN_GREATER_THAN);
      case '@':
        return advanceWithToken(lexer, TokenType.TOKEN_ANON_ID);
      case '?':
        return advanceWithToken(lexer, TokenType.TOKEN_QUESTION);
      case ':':
        return advanceWithToken(lexer, TokenType.TOKEN_COLON);
      default:
        print('[Line ${lexer.lineNum}] Unexpected ${lexer.currentChar}');
        exit(1);
        break;
    }
  }

  return initToken(TokenType.TOKEN_EOF, '');
}

Token advanceWithToken(Lexer lexer, TokenType type) {
  var value = curString(lexer);
  advance(lexer);
  var token = initToken(type, value);

  skipWhitespace(lexer);

  return token;
}

void advance(Lexer lexer) {
  if (lexer.currentChar != '' && lexer.currentIndex < lexer.contents.length - 1) {
    lexer.currentIndex += 1;
    lexer.currentChar = lexer.contents[lexer.currentIndex];
  }

  else if (lexer.currentIndex == lexer.contents.length - 1) {
    lexer.currentIndex++;
  }
}

void expect(Lexer lexer, String c) {
  if (lexer.currentChar != c) {
    print(
        'Error: [Line ${lexer.lineNum}] Lexer expected the current char to be `$c`, but it was `${lexer.currentChar}`.');
    exit(1);
  }
}

void skipWhitespace(Lexer lexer) {
  while (lexer.currentChar == ' ' ||
      lexer.currentChar == '\n' ||
      lexer.currentChar == '\r') {
    if (lexer.currentChar == '') return;
    advance(lexer);
  }
}

void skipInlineComment(Lexer lexer) {
  while (lexer.currentChar != '\n' && lexer.currentChar != '\n') {
    advance(lexer);
  }
}

void skipBlockComment(Lexer lexer) {
  while (true) {
    advance(lexer);

    if (lexer.currentChar == '*') {
      advance(lexer);

      if (lexer.currentChar == '/') {
        advance(lexer);
        return;
      }
    }
  }
}

Token collectString(Lexer lexer) {
  expect(lexer, '"');

  advance(lexer);

  var initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '"') {
    if (lexer.currentIndex == lexer.contents.length - 1) {
      print('[Line ${lexer.lineNum}] Missing closing `"`');
      exit(1);
    }

    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  advance(lexer);

  var token = initToken(TokenType.TOKEN_STRING_VALUE, value);

  return token;
}

Token collectSingleQuoteString(Lexer lexer) {
  expect(lexer, '\'');

  advance(lexer);

  var initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '\'') {
    if (lexer.currentIndex == lexer.contents.length - 1) {
      print('[Line ${lexer.lineNum}] Missing closing `\'`');
      exit(1);
    }

    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  advance(lexer);

  var token = initToken(TokenType.TOKEN_STRING_VALUE, value);

  return token;
}

Token collectNumber(Lexer lexer) {
  var type = TokenType.TOKEN_INT_VALUE;
  var value = '';

  while (isNumeric(lexer.currentChar)) {
    value += curString(lexer);
    advance(lexer);
  }

  if (lexer.currentChar == '.') {
    type = TokenType.TOKEN_DOUBLE_VALUE;
    value += curString(lexer);
    advance(lexer);

    while (isNumeric(lexer.currentChar)) {
      value += curString(lexer);
      advance(lexer);
    }
  }

  return initToken(type, value);
}

Token collectId(Lexer lexer) {
  var initialIndex = lexer.currentIndex;

  while (RegExp('[a-zA-Z0-9]').hasMatch(lexer.currentChar) ||
      lexer.currentChar == '_') {
    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  return initToken(TokenType.TOKEN_ID, value);
}

// I followed my C version of birb and was too lazy to remove this by the time I remembered it is redundant
String curString(Lexer lexer) {
  return lexer.currentChar;
}

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null || int.tryParse(s) != null;
}
