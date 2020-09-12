import 'package:Birb/utils/exceptions.dart';

import 'package:Birb/lexer/token.dart';

class Lexer {
  String program;
  String currentChar;
  int currentIndex;
  int lineNum;
}

/// Initializes and returns a new lexer
Lexer initLexer(String program) {
  final lexer = Lexer()
    ..program = program.trim()
    ..currentIndex = 0
    ..lineNum = 1;
  lexer.currentChar = program.isEmpty ? '' : lexer.program[lexer.currentIndex];

  return lexer;
}

/// Grabs next token from the lexer
Token getNextToken(Lexer lexer) {
  while (
      lexer.currentIndex < lexer.program.length && lexer.currentChar != null) {
    // Skip
    if (lexer.currentChar == ' '
        || lexer.currentChar == '\n'
        || lexer.currentChar == '\r')
      skipWhitespace(lexer);

    // Collect a num
    if (isNumeric(lexer.currentChar)) {
      return collectNumber(lexer);
    }

    if (lexer.currentChar == 'r') {
      advance(lexer);

      if (lexer.currentChar == '"')
        collectString(lexer, true);
      else if (lexer.currentChar == "'")
        collectSingleQuoteString(lexer, true);

      if (RegExp('[a-zA-Z_]').hasMatch(lexer.currentChar)) {
        return collectId(lexer, 'r');
      }
    }

    // Collect identifiers
    if (RegExp('[a-zA-Z_]').hasMatch(lexer.currentChar)) {
      return collectId(lexer);
    }

    switch (lexer.currentChar) {
      case '+':
        String value = lexer.currentChar;
        TokenType type = TokenType.TOKEN_PLUS;
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
      case '-':
        String value = lexer.currentChar;
        TokenType type = TokenType.TOKEN_SUB;

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
      case '*':
        String value = lexer.currentChar;
        TokenType type = TokenType.TOKEN_MUL;
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
      case '&':
        String value = lexer.currentChar;
        advance(lexer);

        // &&
        if (lexer.currentChar == '&') {
          value += lexer.currentChar;

          advance(lexer);

          return initToken(TokenType.TOKEN_AND, value);
        }

        return initToken(TokenType.TOKEN_BITWISE_AND, value);
        break;
      case '|':
        String value = lexer.currentChar;
        advance(lexer);

        // ||
        if (lexer.currentChar == '|') {
          value += lexer.currentChar;
          advance(lexer);
          return initToken(TokenType.TOKEN_OR, value);
        }

        return initToken(TokenType.TOKEN_BITWISE_OR, value);

      case '<':
        String value = lexer.currentChar;
        advance(lexer);

        // <<
        if (lexer.currentChar == '<') {
          value += lexer.currentChar;
          advance(lexer);
          return initToken(TokenType.TOKEN_LSHIFT, value);
        }

        // <=
        if (lexer.currentChar == '=') {
          value += lexer.currentChar;
          advance(lexer);
          return initToken(TokenType.TOKEN_LESS_THAN_EQUAL, value);
        }

        return initToken(TokenType.TOKEN_LESS_THAN, value);
      case '>':
        String value = lexer.currentChar;
        advance(lexer);

        // >>
        if (lexer.currentChar == '>') {
          value += lexer.currentChar;
          advance(lexer);
          return initToken(TokenType.TOKEN_RSHIFT, value);
        }

        // >=
        if (lexer.currentChar == '=') {
          value += lexer.currentChar;
          advance(lexer);
          return initToken(TokenType.TOKEN_GREATER_THAN_EQUAL, value);
        }

        return initToken(TokenType.TOKEN_GREATER_THAN, value);
      case '=':
        String value = lexer.currentChar;
        TokenType type = TokenType.TOKEN_EQUAL;

        advance(lexer);

        // ==
        if (lexer.currentChar == '=') {
          type = TokenType.TOKEN_EQUALITY;
          value += lexer.currentChar;

          advance(lexer);
        }

        // =>
        if (lexer.currentChar == '>') {
          type = TokenType.TOKEN_INLINE;
          value += lexer.currentChar;

          advance(lexer);
        }

        return initToken(type, value);
      case '!':
        String value = lexer.currentChar;
        TokenType type = TokenType.TOKEN_NOT;
        advance(lexer);

        // !=
        if (lexer.currentChar == '=') {
          type = TokenType.TOKEN_NOT_EQUAL;
          value += lexer.currentChar;
          advance(lexer);
        }

        return initToken(type, value);
      case '/':
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

    // END OF FILE
    if (lexer.currentChar == '' || lexer.currentChar == null)
      return initToken(TokenType.TOKEN_EOF, '');

    switch (lexer.currentChar) {
      case '"':
        return collectString(lexer);
      case "'":
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
      case '~':
        return advanceWithToken(lexer, TokenType.TOKEN_ONES_COMPLEMENT);
      case '^':
        return advanceWithToken(lexer, TokenType.TOKEN_BITWISE_XOR);
      case '@':
        return advanceWithToken(lexer, TokenType.TOKEN_ANON_ID);
      case '?':
        return advanceWithToken(lexer, TokenType.TOKEN_QUESTION);
      case ':':
        return advanceWithToken(lexer, TokenType.TOKEN_COLON);
      default:
        throw UnexpectedTokenException(
            '[Line ${lexer.lineNum}] Unexpected ${lexer.currentChar}');
        break;
    }
  }

  // END OF FILE
  return initToken(TokenType.TOKEN_EOF, '');
}

/// Advances to the next character
void advance(Lexer lexer) {
  if (lexer.currentChar != '' &&
      lexer.currentIndex < lexer.program.length - 1) {
    lexer.currentIndex += 1;
    lexer.currentChar = lexer.program[lexer.currentIndex];
  } else if (lexer.currentIndex == lexer.program.length - 1) {
    lexer.currentIndex++;
    lexer.currentChar = null;
  }
}

/// Checks whether the input has been fully consumed
bool isAtEnd(Lexer lexer) {
  return lexer.currentIndex == lexer.program.length;
}

/// Advances while returning a Token
Token advanceWithToken(Lexer lexer, TokenType type) {
  final String value = lexer.currentChar;
  final Token token = initToken(type, value);

  advance(lexer);
  skipWhitespace(lexer);

  return token;
}

/// Expects a character and throws UnexpectedTokenException if
/// the wrong character is received
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

    if (lexer.currentChar == '')
      return;

    if (lexer.currentChar == '\n')
      ++lexer.lineNum;
    advance(lexer);
  }
}

/// Skip comments since they are only notes for the developers
void skipInlineComment(Lexer lexer) {
  while (lexer.currentChar != '\n' &&
      lexer.currentChar != '\n' &&
      !isAtEnd(lexer)) {
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
Token collectString(Lexer lexer, [bool isRaw = false]) {
  expect(lexer, '"');
  advance(lexer);

  final int initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '"') {
    if (lexer.currentIndex == lexer.program.length - 1)
      throw UnexpectedTokenException(
          '[Line ${lexer.lineNum}] Missing closing `"`');

    advance(lexer);
  }

  final String value = lexer.program.substring(initialIndex, lexer.currentIndex);
  final Token token = initToken(TokenType.TOKEN_STRING_VALUE, isRaw ? value : value.escape());

  advance(lexer);

  return token;
}

/// Collect a string from within single quotation marks
Token collectSingleQuoteString(Lexer lexer, [bool isRaw = false]) {
  expect(lexer, '\'');
  advance(lexer);

  final int initialIndex = lexer.currentIndex;

  while (lexer.currentChar != '\'') {
    if (lexer.currentIndex == lexer.program.length - 1)
      throw UnexpectedTokenException(
          '[Line ${lexer.lineNum}] Missing closing `\'`');

    advance(lexer);
  }

  final String value = lexer.program.substring(initialIndex, lexer.currentIndex);
  final Token token = initToken(TokenType.TOKEN_STRING_VALUE, isRaw ? value : value.escape());

  advance(lexer);

  return token;
}

/// Collect numeric tokens
Token collectNumber(Lexer lexer) {
  TokenType type = TokenType.TOKEN_INT_VALUE;
  String value = '';

  if (lexer.currentChar == '0') {
    value += lexer.currentChar;
    advance(lexer);

    // 0x | 0X
    if (lexer.currentChar == 'x' || lexer.currentChar == 'X') {
      value += lexer.currentChar;
      advance(lexer);

      while (RegExp('[0-9a-fA-F]').hasMatch(lexer.currentChar)) {
        value += lexer.currentChar;
        advance(lexer);
      }

      return initToken(TokenType.TOKEN_INT_VALUE, value);
    }
  }

  while (isNumeric(lexer.currentChar)) {
    value += lexer.currentChar;
    advance(lexer);
  }

  // double
  if (lexer.currentChar == '.') {
    if (isNumeric(lexer.program[lexer.currentIndex + 1])) {
      type = TokenType.TOKEN_DOUBLE_VALUE;
      value += lexer.currentChar;

      advance(lexer);

      while (isNumeric(lexer.currentChar)) {
        value += lexer.currentChar;
        advance(lexer);
      }
    }
  }

  if (lexer.currentChar == 'e') {
    type = TokenType.TOKEN_DOUBLE_VALUE;
    value += lexer.currentChar;

    advance(lexer);

    if (lexer.currentChar == '+' || lexer.currentChar == '-') {
      value += lexer.currentChar;

      advance(lexer);
    }

    while (isNumeric(lexer.currentChar)) {
      value += lexer.currentChar;
      advance(lexer);
    }
  }

  return initToken(type, value);
}

/// Collects identifiers
Token collectId(Lexer lexer, [String prefix = '']) {
  final int initialIndex = lexer.currentIndex;

  // Identifiers can only start with `_` or any alphabet
  if (RegExp('[a-zA-Z_]').hasMatch(lexer.currentChar)) {
    advance(lexer);

    while (RegExp('[a-zA-Z0-9_]').hasMatch(lexer.currentChar))
      advance(lexer);
  }

  // Nullable?
  if (lexer.currentChar == '?' && RegExp(r'\s').hasMatch(lexer.program[lexer.currentIndex + 1])) {
    advance(lexer);
  }

  return initToken(TokenType.TOKEN_ID,
      prefix + lexer.program.substring(initialIndex, lexer.currentIndex));
}

/// Check if the character is numeric
bool isNumeric(String s) {
  if (s == null) {
    return false;
  } else {
    return double.tryParse(s) != null || int.tryParse(s) != null;
  }
}

extension on String {
  String escape() {
    String escapedString = this;

    escapedString = escapedString
    .replaceAll(r'\f', '\x0C')
    .replaceAll(r'\n', '\x0A')
    .replaceAll(r'\r', '\x0D')
    .replaceAll(r'\t', '\x09')
    .replaceAll(r'\v', '\x0B')
    .replaceAll(r'\\', '\x5C')
    .replaceAll(r"\'", '\x27')
    .replaceAll(r'\"', '\x22')
    .replaceAllMapped(RegExp(r'\\x(.){2}'), (m) => String.fromCharCode(int.parse(m.group(1), radix: 16)))
    .replaceAll(r'\$', '\$')
    .replaceAll(r'$', '\x1B[');

    return escapedString;
  }
}
