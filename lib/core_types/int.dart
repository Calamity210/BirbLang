import 'package:Birb/utils/AST.dart';

/// Visits properties for `Int`s
AST visitIntProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isEven':
      // isEven returns a bool, so we create an ast with a bool type
      // CHECK THE ASTType ENUM IN AST.dart to see other types
      AST boolAST = initAST(ASTType.AST_BOOL);

      // Left is our int as an AST, its value is held in `intVal`
      boolAST.boolValue = left.intVal % 2 == 0; // Divisible by 2?

      // Now we simply return the boolAST
      return boolAST;

  }
}


/// Visits methods for `Int`s
AST visitIntMethods(AST node, AST left) {
  // Properties should be sufficient for now, ping me on discord and I'll explain how methods would work
}