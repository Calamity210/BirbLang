fieldsTypes = {}
with open('lib/utils/ast/ast_node.dart') as f:
    lines = list(map(lambda l: l.strip(), f.readlines()))
    lines = lines[lines.index('class ASTNode implements AST {') : ]
    for line in lines:
        if ' get ' in line: # getter
            field = line.split(' get ')
            type, name = field[0], field[1].split(' ')[0]
            fieldsTypes[name] = type

with open('misc/types') as f:
    lines = f.readlines()[1:]

lines = [line.strip().split(' ') for line in lines if line.strip() != '']

classes = []
with open('lib/utils/ast/ast_types.dart', 'w') as f:
    f.write('''
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/lexer/token.dart';
import 'package:Birb/utils/AST.dart';

'''
    )
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
                f.write(f'  {fieldsTypes[name]} {name} = {value};\n\n')
            else:
                f.write(f'  {fieldsTypes[field]} {field};\n\n')
        f.write('}\n\n')

    f.write('AST initAST(ASTType type) {\n')
    for type, kls in classes:
        f.write(f'''  if (type == ASTType.AST_{type}) return {kls}();\n''')
    f.write('  return AST();\n')
    f.write('}')
