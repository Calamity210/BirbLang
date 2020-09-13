---
id: tour
title: Tour
sidebar_label: Tour
slug: /
---

## Small program
```birb
void multiplyAndScrem(int a, int b) {
  var product = a * b;
  screm(a + ' * ' + b + ' = ' + product);
}

multiplyAndScrem(5, 2); // Should screm (5 * 2 = 10)
```
Key things to note from this program are:

- `void` is a data type that expects no return value.
- `multiplyAndScrem` is the name of a function, a function is a way to reuse code without having to necessarily type it all again.
- Everything with in the `()` after the functions name are parameters, `a and b` are the names `int` is the type.
- `var` is a way to declare a variable without specifying a type.
- `screm` is birb's way of writing to stdout.
- Everything on a line after `//` is a comment (ignored by the program).

## Modifiers
- final - Can't reassign variable
- const - compile time variable (can't reassign)
- static

:::caution
Static modifiers are still a work in progress
:::

## Data Types

Supported data types yet are:

- `bool` - true or false.
- `class` - Encapsulates data for an object.
- `double` - Birb doubles are 64-bit floating-point numbers as specified in the IEEE 754 standard. 1 bit for the sign, 11 for exponents and 52 for the value itself.
- `enum` - Enumerated type, used to define constant values
- `int` - Basic integer type, 64-bit 2's complement.
- `List` - A collection of dynamic objects with a length.
- `Map` - Key / Value pairs, key must be a String.
- `Source` - source code from an included file.
- `String` - Literals (char array), surrounded by either `"` or `'`s.
- `var` - Allows birb to infer the type

## Primitive Types example
 ```birb
String str = "Henlo\nbirb"; // \n is taken as an escape character
String raw = r'Henlo\nbirb'; // \n is taken literally


int length = str.length; // 10

double d = length / 2; // 5.0

bool isGreaterThanFive = d > 5; // false
```

## Class example
```birb
class Birb {
  String name = "Birb";
  int age = 5;
  bool isMale = true;
  
  void sayName() {
    screm(nest.name); // Birb
  } 
}
```

:::tip What is nest?
Nest is a keyword used to refer to the current instance.
:::

## List example
```birb
List list = ["Seeb",10, false];

int length = list.length; // 3
```

## Map example
```birb
Map food = {
  "veg": ["carrot", "lettuce"]
};

List i = food["veg"];

screm(i[0]); // carrot
```

## Variables

Variables in Birb are *Explicitly Typed* meaning its type must be declared. 
To define a variable, specify the type, followed by its name and value.

```birb
String foo = "henlo";
```
:::info What if I don't want to specify a type
Use `var` to let birb imply the variables type
:::
Descendant scopes in birb will access the most recent declared variable.

## Loops

While loop:
```birb
int i = 0;

while(i < 9) {
  screm(i);
  i++;
}
```
`continue` is used to jump to the next iteration of a loop, while `break` is used to stop a loop.
A for loop requires an `initialization, condition, and change`. Separate them with a semicolon `;`.

```birb
for (int i = 0; i < 9; i++) {
    screm(i);
}
```

:::info 
In both cases the braces `{}` are only required if you are specifying more than one statement.
:::

## Control-flow

If statements in Birb work just like they would in other languages. Just as loops, the brackets are optional unless you are specifying more than one statement.

A switch requires the default case, even if it is empty.

```birb
int i = 10;

// if/else
if (i < 10)
screm(i);
else 
screm('i is not less than 10');

// switch
switch(i) {
  case 10: {
    screm("i is 10");
  } 
  default: {
    screm("i is not 10");
  }
}

// ternary
i == 10 ? 
screm("i is 10") :
screm("i is not 10");

```


## Comments

Comments are similar to a majority of other languages;
`//` For single-line and `/* */` for multi-line.

```birb
// This is a single-line comment.

/*
This is a multi-line comment.
*/
```

## Keywords
|assert|enum|nest|throw|
| -- | -- | -- | -- |
|break|follows|new|true|
|case|false|next|var|
|class|final|noSeeb|void|
|const|for|return|while|
|default|grab|static||
|else|if|switch||