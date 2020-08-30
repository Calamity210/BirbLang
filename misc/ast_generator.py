with open('misc/types') as f:
    lines = f.readlines()[1:]

lines = [line.strip().split(' ') for line in lines if line.strip() != '']

classes = []
with open('lib/utils/ast/ast_types.dart', 'w') as f:
    f.write("import 'ast_node.dart';\n")
    f.write("import '../AST.dart';\n\n")
    for astType in lines:
        type, name, fields = astType[0], astType[1], astType[2:]
        classes.append((type, name))
        f.write(f'class {name} extends ASTNode {{\n')
        f.write('  @override\n')
        f.write(f'  ASTType type = ASTType.AST_{type};\n\n')
        for field in fields:
            f.write(f'  @override\n')
            if '=' in field:
                name, value = field.split('=')
                f.write(f'  var {name} = {value};\n\n')
            else:
                f.write(f'  var {field};\n\n')
        f.write('}\n\n')

    f.write('AST initAST(ASTType type) {\n')
    for type, kls in classes:
        f.write(f'''  if (type == ASTType.AST_{type}) return {kls}();\n''')
    f.write('  return AST();\n')
    f.write('}')
