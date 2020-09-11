---
id: string
title: String
---

An array of chars (UTF-16 code units).

A data type used mainly to represent text, denoted by the `'` or `"` its wrapped within.

You can indicate that a String is raw and should treat `\` as a literal character by prefixing it with `r`. Strings in birb are multiline by default:

```dart
screm("This string will print on one line");

// OR

screm("
This String
will print on two lines
");
```

You can use the `+` operator to concat Strings:

```dart
screm("Henlo " + "birb!") // "Henlo birb!"
```

## Properties

### codeUnits

`List codeUnits`

Returns a list containing the 16-bit Unicode code units of this String.

**Example**
```dart
String birb = "birb";
List codeUnits = birb.codeUnits; // [98, 105, 114, 98]
```


### isEmpty

`bool isEmpty`

True if this String is empty.

**Example**
```dart
String birb = "birb";
bool isEmpty = birb.isEmpty; // false
```

### isNotEmpty

`bool isNotEmpty`

True if this String is not empty.

**Example**
```dart
String birb = "birb";
bool isNotEmpty = birb.isNotEmpty; // true
```

### length

`int length`

Returns an int containing the length of this String.

**Example**
```dart
String birb = "birb";
int length = birb.length; // 4
```

### mock 

`String mock`

Prints this String before reading a line from StdIn.

**Example**
```dart
String question = "What is your name?";
String name = question.mock;
```

### toBinary

`List toBinary`

Returns a list with the strings code units represented as binary.

**Example**
```dart
String parrot = "Parrot";
List binary = parrot.toBinary;
```

### toHex

`List toHex`

Returns a list with the strings code units represented as hexadecimal.

**Example**
```dart
String parrot = "Parrot";
List hex = parrot.toHex;
```

### toOct

`List toOct`

Returns a list with the strings code units represented as octal.

**Example**
```dart
String parrot = "Parrot";
List oct = parrot.toOct;
```

### runtimeType

`String runtimeType`

Returns a list with the strings code units represented as octal.

**Example**
```dart
String roar = "Roar";
String type = roar.runtimeType; // String
```

## Methods

### codeUnitAt

`int codeUnitAt(int index)`

Returns the codeUnit at the given index.

**Example**
```dart
String birb = "birb";
int codeUnit = birb.codeUnitAt(0); // 98
```

### compareTo

`int compareTo(String str)`

Compares the codeUnits of this String to `str`. The returned in is negative if this String is ordered before `str`, positive if after and zero if they are the same. 

**Example**
```dart
String birb = "birb";
int compareValue = birb.compareTo("seeb"); // -1
```

### contains

`bool contains(String other, int startIndex)`

Returns true if this String contains `other` at or after the startIndex.

**Example**
```dart
String birb = "birb";
bool contains = birb.contains("b"); // true
```

### endsWith

`bool endsWith(String str)`

Returns true if this String ends with `str`.

**Example**
```dart
String seeb = "seeb";
bool endsWith = seeb.endsWith("b"); // true
```

### indexOf

`int indexOf(String str, int start)`

Returns the index of the first match of `str` starting from `start` within this `String`.

**Example**
```dart
String birb = "birb";
int index = birb.indexOf("b", 1); // 3
```

### lastIndexOf

`int lastIndexOf(String str, int start)`

Returns the index of the last match of `str` starting from `start` within this `String`.

**Example**
```dart
String birb = "birb";
int index = birb.lastIndexOf("b", 0); // 3
```

### padLeft

`String padLeft(int width, String padding)`

Adds `padding` to the left of this String while it is smaller than `width` and returns a new String.

**Example**
```dart
String birb = "birb";
String padded = birb.padLeft(6, '>'); // >>birb
```

### padRight

`String padRight(int width, String padding)`

Adds `padding` to the right of this String while it is smaller than `width` and returns a new String.

**Example**
```dart
String birb = "birb";
String padded = birb.padRight(6, '<'); // birb<<
```

### replaceAll

`String replaceAll(String from, String replace)`

Replaces all occurrences of `from` with `replace`.

**Example**
```dart
String seeb = "seeb";
String replaced = seeb.replaceAll('b', 'd'); // seed
```

### replaceFirst

`String replaceFirst(String from, String replace)`

Replaces the first occurrences of `from` with `replace`.

**Example**
```dart
String seeb = "seeb";
String replaced = seeb.replaceFirst('b', 'd'); // seed
```

### replaceRange

`String replaceRange(int start, int end, String replace)`

Replaces a substring between `start` and `end` with `replace`.

**Example**
```dart
String seeb = "seeb";
String replaced = seeb.replaceRange(0, 3, 'henlo'); // henlo
```

### split

`List split(String str)`

Splits the String at all occurrences of `str`.

**Example**
```dart
String henlo = "Henlo Birb";
List words = henlo.split(" "); // ['Henlo', 'Birb']
```

### startsWith

`bool startsWith(String str)`

Returns true if this String starts with `str`.

**Example**
```dart
String seeb = "seeb";
bool startsWith = seeb.startsWith("s"); // true
```

### substring

`String substring(int start, int end)`

Returns a substring of this String between `start` and `end`.

**Example**
```dart
String henlo = "Henlo Birb";
String substr = henlo.substring(0, 4); // Henlo
```

### toLowerCase

`String toLowerCase()`

Returns this String as lower case.

**Example**
```dart
String henlo = "Henlo Birb";
String lowerCase = henlo.toLowerCase(); // henlo birb
```

### toUpperCase

`String toUpperCase()`

Returns this String as upper case.

**Example**
```dart
String henlo = "Henlo Birb";
String upperCase = henlo.toUpperCase(); // HENLO BIRB
```

### trim

`String trim()`

Returns this String without any leading or trailing whitespace.

**Example**
```dart
String henlo = "   Henlo Birb   ";
String trimmed = henlo.trim(); /*Henlo Birb*/
```

### trimLeft

`String trimLeft()`

Returns this String without any leading whitespace.

**Example**
```dart
String henlo = "   Henlo Birb   ";
String trimmed = henlo.trimLeft(); /*Henlo Birb   */
```

### trimRight

`String trimRight()`

Returns this String without any trailing whitespace.

**Example**
```dart
String henlo = "   Henlo Birb   ";
String trimmed = henlo.trimRight(); /*   Henlo Birb*/
```
