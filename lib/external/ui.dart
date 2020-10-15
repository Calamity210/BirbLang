import 'dart:ffi';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/runtime/runtime.dart';

import 'package:Birb/ui/gl/gl.dart';
import 'package:Birb/ui/glfw/glfw.dart';

import 'package:ffi_utils/ffi_utils.dart';

Map keyCall = {};
Map mouseCall = {};

void registerUi(Runtime runtime) {
  runtime.registerGlobalVariable('Window', windowClass(runtime));
}

void keyCallback(Pointer<GLFWwindow> window, int key, int scancode, int action, int mods) async {
  final call = FuncCallNode();
  call.funcName = keyCall['func'].funcName;
  call.functionCallArgs = [IntNode()..intVal = key, IntNode()..intVal = action];
  call.funcCallExpression = VariableNode()..variableName = keyCall['func'].funcName;

  await keyCall['runtime'].visitFuncCall(call);
}

void mouseCallback(Pointer<GLFWwindow> window, int xPos, int yPos) async {
  final call = FuncCallNode();
  call.funcName = mouseCall['func'].funcName;
  call.functionCallArgs = [IntNode()..intVal = xPos, IntNode()..intVal = yPos];
  call.funcCallExpression = VariableNode()..variableName = mouseCall['func'].funcName;

  await mouseCall['runtime'].visitFuncCall(call);
}

ASTNode windowClass(Runtime runtime) {
  final ClassNode object = ClassNode();

  Pointer windowInstance;
  int width;
  int height;
  
  final FuncDefNode init = FuncDefNode();

  init.funcName = 'init';
  init.funcPointer = (_, __, ___) {
    initGlew();
    initGlfw();
    glfwInit();

    return AnyNode();
  };

  object.classChildren.add(init);

  final FuncDefNode create = FuncDefNode();

  create.funcName = 'create';
  create.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [IntNode, IntNode, StringNode]);

    windowInstance = glfwCreateWindow(args[0].intVal, args[1].intVal, NativeString.fromString(args[2].stringValue), nullptr.cast(), nullptr.cast());

    width = args[0].intVal;
    height = args[1].intVal;

    glfwMakeContextCurrent(windowInstance);

    glViewport(0, 0, width, height);

    return AnyNode();
  };

  object.classChildren.add(create);

  final FuncDefNode running = FuncDefNode();
  running.funcName = 'running';
  running.funcPointer = (_, __, ___) {
    bool windowShouldClose;

    if (glfwWindowShouldClose(windowInstance) != GLFW_TRUE) {
      windowShouldClose = true;
    }

    else {
      windowShouldClose = false;
    }

    return BoolNode()..boolVal = windowShouldClose;
  };

  object.classChildren.add(running);

  final FuncDefNode continueLoop = FuncDefNode();

  continueLoop.funcName = 'continueLoop';
  continueLoop.funcPointer = (_, __, ___) {
    glfwSwapBuffers(windowInstance);
    glfwPollEvents();
    glFlush();

    return AnyNode();
  };

  object.classChildren.add(continueLoop);

  final FuncDefNode terminate = FuncDefNode();

  terminate.funcName = 'terminate';
  terminate.funcPointer = (_, __, ___) {
    glfwTerminate();

    return AnyNode();
  };

  object.classChildren.add(terminate);

  final FuncDefNode opacity = FuncDefNode();

  opacity.funcName = 'setOpacity';
  opacity.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [DoubleNode]);

    glfwSetWindowOpacity(windowInstance, args[0].doubleVal);

    return AnyNode();
  };

  object.classChildren.add(opacity);

  final FuncDefNode clear = FuncDefNode();

  clear.funcName = 'clear';
  clear.funcPointer = (_, __, List<ASTNode> args) {
    if (args.length == 1) {
      expectArgs(args, [ListNode]);

      glClearColor(args[0].listElements[0].doubleVal/255, args[0].listElements[1].doubleVal/255, args[0].listElements[2].doubleVal/255, 1);
      glClear(GL_COLOR_BUFFER_BIT);
    }
    else {
      glClear(GL_COLOR_BUFFER_BIT);
    }

    return AnyNode();
  };

  object.classChildren.add(clear);

  final FuncDefNode drawPoint = FuncDefNode();

  drawPoint.funcName = 'drawPoint';
  drawPoint.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [DoubleNode, DoubleNode, DoubleNode]);

    glPointSize(args[2].doubleVal);

    glBegin(GL_POINTS);
    glVertex2f(args[0].doubleVal/width, args[1].doubleVal/height);
    glEnd();

    return AnyNode();
  };

  object.classChildren.add(drawPoint);

  final FuncDefNode drawTriangle = FuncDefNode();

  drawTriangle.funcName = 'drawTriangle';
  drawTriangle.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [DoubleNode, DoubleNode, DoubleNode, DoubleNode, DoubleNode, DoubleNode]);

    glBegin(GL_TRIANGLES);
    glVertex2f(args[0].doubleVal/width, args[1].doubleVal/height);
    glVertex2f(args[2].doubleVal/width, args[3].doubleVal/height);
    glVertex2f(args[4].doubleVal/width, args[5].doubleVal/height);
    glEnd();

    return AnyNode();
  };

  object.classChildren.add(drawTriangle);

  final FuncDefNode drawLine = FuncDefNode();

  drawLine.funcName = 'drawLine';
  drawLine.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [DoubleNode, DoubleNode, DoubleNode, DoubleNode]);

    glBegin(GL_LINES);
    glVertex2f(args[0].doubleVal/width, args[1].doubleVal/height);
    glVertex2f(args[2].doubleVal/width, args[3].doubleVal/height);
    glEnd();

    return AnyNode();
  };

  object.classChildren.add(drawLine);

  final FuncDefNode color = FuncDefNode();

  color.funcName = 'setColor';
  color.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [ListNode]);

    glColor3f(args[0].listElements[0].doubleVal/255, args[0].listElements[1].doubleVal/255, args[0].listElements[2].doubleVal/255, 1);

    return AnyNode();
  };

  object.classChildren.add(color);

  final FuncDefNode translate = FuncDefNode();

  translate.funcName = 'translate';
  translate.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [DoubleNode, DoubleNode]);

    glTranslatef(args[0].doubleVal/width, args[1].doubleVal/height, 0.0);

    return AnyNode();
  };

  object.classChildren.add(translate);

  final FuncDefNode push = FuncDefNode();

  push.funcName = 'push';
  push.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, []);

    glPushMatrix();

    return AnyNode();
  };

  object.classChildren.add(push);

  final FuncDefNode pop = FuncDefNode();

  pop.funcName = 'pop';
  pop.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, []);

    glPopMatrix();

    return AnyNode();
  };

  object.classChildren.add(pop);

  final FuncDefNode onKeyPress = FuncDefNode();

  onKeyPress.funcName = 'onKeyPress';
  onKeyPress.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [FuncDefNode]);
    keyCall['func'] = args[0]; 
    keyCall['runtime'] = runtime;
    glfwSetKeyCallback(windowInstance, Pointer.fromFunction<Void Function(Pointer<GLFWwindow> window, Int32 key, Int32 scancode, Int32 action, Int32 mods)>(keyCallback));

    return AnyNode();
  };

  object.classChildren.add(onKeyPress);

  final FuncDefNode onMouseEvent = FuncDefNode();

  onMouseEvent.funcName = 'onMouseEvent';
  onMouseEvent.funcPointer = (_, __, List<ASTNode> args) {
    expectArgs(args, [FuncDefNode]);
    mouseCall['func'] = args[0]; 
    mouseCall['runtime'] = runtime;
    glfwSetCursorPosCallback(windowInstance, Pointer.fromFunction<Void Function(Pointer<GLFWwindow> window, IntPtr x, IntPtr y)>(mouseCallback));

    return AnyNode();
  };

  object.classChildren.add(onMouseEvent);

  return object;
}