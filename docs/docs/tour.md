---
id: tour
title: Tour
sidebar_label: Tour
slug: /
---

# Basics


## Small program
```dart
class Birb {
  String favouriteGreeting = 'Henlo';
  String name = 'Birb';
  int age = 10;
  List favouriteFood = ['Seeb', 'Seeb', 'Seeb'];
  Map goodBadMap = {
        'good': ['Seeb'],
        'bad': 'rest',
        'goodCount': 1,
        'badCount': 'ERROR'
  };
}


List favouriteFood = Birb.favouriteFood;
Map goodBadMap = Birb.goodBadMap;

void printDetails() {
    screm(Birb.favouriteGreeting + " am " + Birb.name);
    screm("I am " + Birb.age + " years old");
    screm("I like " + favouriteFood[0]);
    screm('There is only ' + goodBadMap['goodCount'] + " item in my good list");
}

printDetails();

```
## Modifiers

- final - Can't reassign variable
- const - compile time variable (can't reassign)
- static - TODO

## Data Types

Supported data types yet are:

- var - Allows birb to infer the type
- int - Basic integer type, 64-bit 2's complement.
- double - Birb doubles are 64-bit floating-point numbers as specified in the IEEE 754 standard. 1 bit for the sign, 11 for exponents and 52 for the value itself.
- String - Literals (char array), surrounded by either `"` or `'`s.
- bool - true or false.
- Source - source code from an included file.
- List - A collection of dynamic objects with a length.
- Map - Key / Value pairs, key must be a String.
- class - Encapsulates data for an object.
- enum - Enumerated type, used to define constant values

## Primitive Types example
 ```dart
String str = "Henlo birb";

int length = str.length;

double d = length * 0.5;

bool isGreaterThanFive = d > 5;
```

## Class example
The `nest` keyword is birb's equivalent of `this`
```dart
class Birb {

  String name = "Birb";
  int age = 5;
  bool isMale = true;
  
  void sayName() {
    screm(nest.name);
  } 
}
```

## List example
```dart
List list = ["Seeb",10, false];

list.add("More seeb");
list.remove(2);

int length = list.length;
```

## Map example
```dart
Map food = {
  "veg": ["carrot", "lettuce"]
};

List i = food["veg"];

screm(i[0]);
```

## Variables

Variables in Birb are *Explicitly Typed* meaning its type must be declared. 
To define a variable, specify the type, followed by its name and value.

```dart
String foo = "henlo";
```
Birb is also lexically scoped, descendant scopes will access the most recent declared variable


## Loops

While loop:
```dart
int i = 0;

while(i < 9) {
  screm(i);
  i++;
}
```
`continue` is used to jump to the next iteration of a loop, while `break` is used to stop a loop.
A for loop requires an `initialization, condition, and change`. Separate them with a semicolon `;`.

```dart
for (int i = 0; i < 9; i++) {
    screm(i);
}
```

In both cases the braces `{}` are only required if you are specifying more than one statement.

## Control-flow

If statements in Birb work just like they would in other languages. Just as loops, the brackets are optional unless you are specifying more than one statement.

A switch requires the default case, even if it is empty.

```dart
int i = 10;

if (i < 10)
screm(i);
else 
screm('i is not less than 10');

switch(i) {
  case 10: {
    screm("i is 10");
  } 
  default: {
    screm("i is not 10");
  }
}

i == 10 ? 
screm("i is 10") :
screm("i is not 10");

```


## Comments

Comments are similar to a majority of other languages;
`//` For single-line and `/* */` for multi-line.

```dart
// This is a single-line comment.

/*
This is a multi-line comment.
*/
```

## Standard Methods
 - Date
 - decodeJson
 - encodeJson
 - exit
 - grab
 - mock
 - screm
 - Time
 
 ### Date
 Get the current date, returns a class type with the following structure:
 
 
 ```dart
class Date {
  int day;
  int month;
  int year;
  int weekday;
}
```


To use it:


```dart
class date = Date;
screm(date.day + " " + date.month + " " + date.year);
```


### exit
Exits the program with the given code:
```dart
exit(1);
```

### grab
Returns the source code from a file, while allowing you to import a file:
```dart
grab("henlo.birb");
```

### mock
Grab user input (STDIN):
```dart
screm("What is your name?")
String name = mock();
screm("Hi "+ name);

// OR

String msg = "What is your name";
String name = msg.mock;
screm("Hi " + name);
```

 ### screm
 Prints a value (STDOUT):
 ```dart
screm("Henlo birb");
```

### Time
Get the current time, returns a class type with the following structure:
 
 ```dart
class Time {
  int hour;
  int minute;
  int second;
  int milliSecond;
}
```

To use it:

```dart
class time = Time;
screm(date.hour + ":" + date.minute);
```