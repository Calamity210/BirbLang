import 'package:Birb/utils/exceptions.dart';

import 'token.dart';

class Lexer {
  /// The program to lex
  String contents;
  String currentChar;

  int currentIndex;
  int lineNum;
}

/// Takes in a string of content(programs),
/// Initializes and returns a new lexer
Lexer initLexer(String contents) {
  var lexer = Lexer()
    ..contents = contents.trim()
    ..currentIndex = 0
    ..lineNum = 1;
  lexer.currentChar = contents.isEmpty ? '' : lexer.contents[lexer.currentIndex];

  return lexer;
}

/// Grabs next token from the lexer
Token getNextToken(Lexer lexer) {
  while (
      lexer.currentIndex < lexer.contents.length && lexer.currentChar != null) {
    // Skip
    if (lexer.currentChar == ' ' ||
        lexer.currentChar == '\n' ||
        lexer.currentChar == '\r') skipWhitespace(lexer);

    // Collect a num
    if (isNumeric(lexer.currentChar)) {
      return collectNumber(lexer);
    }

    // Collect identifiers
    if (RegExp('[a-zA-Z0-9]').hasMatch(lexer.currentChar)) {
      return collectId(lexer);
    }

    // +
    if (lexer.currentChar == '+') {
      var value = lexer.currentChar;
      var type = TokenType.TOKEN_PLUS;
      advance(lexer);

      // ++
      if (lexer.currentChar == '+') {
        type = TokenType.TOKEN_PLUS_PLUS;
        value += lexer.currentChar;
        advance(lexer);
      }

      // +=
      else if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_PLUS_EQUAL;
        value += lexer.currentChar;
        advance(lexer);
      }

      return initToken(type, value);
    }

    // -
    if (lexer.currentChar == '-') {
      var value = lexer.currentChar;
      var type = TokenType.TOKEN_SUB;

      advance(lexer);

      // --
      if (lexer.currentChar == '-') {
        type = TokenType.TOKEN_SUB_SUB;
        value += lexer.currentChar;

        advance(lexer);
      }

      // -=
      else if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_SUB_EQUAL;
        value += lexer.currentChar;

        advance(lexer);
      }

      return initToken(type, value);
    }

    // *
    if (lexer.currentChar == '*') {
      var value = lexer.currentChar;
      var type = TokenType.TOKEN_MUL;
      advance(lexer);

      // **
      if (lexer.currentChar == '*') {
        type = TokenType.TOKEN_MUL_MUL;
        value += lexer.currentChar;
        advance(lexer);
      }

      // *=
      else if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_MUL_EQUAL;
        value += lexer.currentChar;
        advance(lexer);
      }

      return initToken(type, value);
    }

    // &
    if (lexer.currentChar == '&') {
      var value = lexer.currentChar;

      advance(lexer);

      // &&
      if (lexer.currentChar == '&') {
        value += lexer.currentChar;

        advance(lexer);

        return initToken(TokenType.TOKEN_AND, value);
      }
    }

    if (lexer.currentChar == '|') {
      var value = lexer.currentChar;

      advance(lexer);

      // ||
      if (lexer.currentChar == '|') {
        value += lexer.currentChar;

        advance(lexer);

        return initToken(TokenType.TOKEN_OR, value);
      }
    }

    if (lexer.currentChar == '=') {
      var value = lexer.currentChar;

      var type = TokenType.TOKEN_EQUAL;

      advance(lexer);

      // ==
      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_EQUALITY;
        value += lexer.currentChar;

        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '!') {
      var value = lexer.currentChar;
      var type = TokenType.TOKEN_NOT;
      advance(lexer);

      // !=
      if (lexer.currentChar == '=') {
        type = TokenType.TOKEN_NOT_EQUAL;
        value += lexer.currentChar;
        advance(lexer);
      }

      return initToken(type, value);
    }

    if (lexer.currentChar == '/') {
      advance(lexer);

      // Inline comment
      if (lexer.currentChar == '/') {
        advance(lexer);
        skipInlineComment(lexer);
        continue;
      } else if (lexer.currentChar == '*') {
        // Block comment
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
        return advanceWithToken(lexer, TokenType.TOKEN_LPAREN);
      case ')':
        return advanceWithToken(lexer, TokenType.TOKEN_RPAREN);
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
        throw UnexpectedTokenException('[Line ${lexer.lineNum}] Unexpected ${lexer.currentChar}');
        break;
    }
  }

  return initToken(TokenType.TOKEN_EOF, '');
}

/// Advances to the next character
void advance(Lexer lexer) {
  if (lexer.currentChar != '' &&
      lexer.currentIndex < lexer.contents.length - 1) {
    lexer.currentIndex += 1;
    lexer.currentChar = lexer.contents[lexer.currentIndex];
  } else if (lexer.currentIndex == lexer.contents.length - 1) {
    lexer.currentIndex++;
    lexer.currentChar = null;
  }
}

/// Checks whether the input has been fully consumed
bool isAtEnd(Lexer lexer) {
  return lexer.currentIndex == lexer.contents.length;
}

/// Advances while returning a Token
Token advanceWithToken(Lexer lexer, TokenType type) {
  var value = lexer.currentChar;

  advance(lexer);
  var token = initToken(type, value);

  skipWhitespace(lexer);

  return token;
}

/// Expects a character and throws UnexpectedTokenException if the wrong
/// Character is received
void expect(Lexer lexer, String c) {
  if (lexer.currentChar != c)
    throw UnexpectedTokenException(
        'Error: [Line ${lexer.lineNum}] Lexer expected the current char to be `$c`, but it was `${lexer.currentChar}`.');
}

/// Skips any whitespaces since we don't want to have whitespace tokens
void skipWhitespace(Lexer lexer) {
  while (lexer.currentChar == ' ' ||
      lexer.currentChar == '\n' ||
      lexer.currentChar == '\r') {
    if (lexer.currentChar == '') return;
    if (lexer.currentChar == '\n') ++lexer.lineNum;
    advance(lexer);
  }
}

/// Skip comments since they are only notes for the developers
void skipInlineComment(Lexer lexer) {
  while (lexer.currentChar != '\n' && lexer.currentChar != '\n' && !isAtEnd(lexer)) {
    advance(lexer);
  }
}

/// Skips block comments
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

/// Collect a string from within double quotation marks
Token collectString(Lexer lexer) {
  expect(lexer, '"');

  advance(lexer);

  var initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '"') {
    if (lexer.currentIndex == lexer.contents.length - 1)
     throw UnexpectedTokenException('[Line ${lexer.lineNum}] Missing closing `"`');

    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  advance(lexer);

  var token = initToken(TokenType.TOKEN_STRING_VALUE, value);

  return token;
}

/// Collect a string from within single quotation marks
Token collectSingleQuoteString(Lexer lexer) {
  expect(lexer, '\'');

  advance(lexer);

  var initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '\'') {
    if (lexer.currentIndex == lexer.contents.length - 1)
     throw UnexpectedTokenException('[Line ${lexer.lineNum}] Missing closing `\'`');

    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  advance(lexer);

  var token = initToken(TokenType.TOKEN_STRING_VALUE, value);

  return token;
}

/// Collect numeric tokens
Token collectNumber(Lexer lexer) {
  var type = TokenType.TOKEN_INT_VALUE;
  var value = '';

  while (isNumeric(lexer.currentChar)) {
    value += lexer.currentChar;

    advance(lexer);
  }

  if (lexer.currentChar == '.') {
    type = TokenType.TOKEN_DOUBLE_VALUE;
    value += lexer.currentChar;

    advance(lexer);

    while (isNumeric(lexer.currentChar)) {
      value += lexer.currentChar;

      advance(lexer);
    }
  }

  return initToken(type, value);
}

/// Collects identifiers
Token collectId(Lexer lexer) {
  var initialIndex = lexer.currentIndex;

  while (RegExp('[a-zA-Z0-9]').hasMatch(lexer.currentChar) ||
      lexer.currentChar == '_') {
    advance(lexer);
  }

  var value = lexer.contents.substring(initialIndex, lexer.currentIndex);

  return initToken(TokenType.TOKEN_ID, value);
}

/// Check if the character is numeric
bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null || int.tryParse(s) != null;
}
