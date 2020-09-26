---
id: int
title: int
---

A 64-bit 2s complement integer value.

```dart
int number = 10;
screm(number);
```

## Properties

### isEven

`bool isEven`

Returns true if the integer is even.

**Example**
```dart
int number = 10;
bool isEven = number.isEven; // true
```

### isFinite

`bool isFinite`

Returns true if the integer is a finite value. All values aside from the two infinities and Not-A-Number (NaN) are finite.

**Example**
```dart
int number = 10;
bool isFinite = number.isFinite; // true
```

### isInfinite

`bool isInfinite`

Returns true if the integer is infinite.

**Example**
```dart
int number = 10;
bool isInfinite = number.isInfinite; // false
```

### isNaN

`bool isNaN`

Returns true if the number is the double Not-a-Number value

**Example**
```dart
int number = 10;
bool isNaN = number.isNaN; // false
```


### isNegative

`bool isNegative`

True if the number is negative

**Example**
```dart
int number = 10;
bool isNegative = number.isNegative; // false
```

### isOdd

`bool isOdd`

True if the number is odd.

**Example**
```dart
int number = 10;
bool isOdd = number.isOdd; // false
```

### sign

`int sign`

Returns the sign of this integer. Returns 0, -1 for values less than zero and +1 for values greater than zero.

**Example**
```dart
int number = 10;
bool signValue = number.sign; // 1
```

### runtimeType

`String runtimeType`

Returns the runtime type of this

**Example**
```dart
int number = 10;
bool type = number.runtimeType; // int
```

### bitLength

`int bitLength`

Returns the minimum number of bits required to store this integer.

**Example**
```dart
int number = 10;
bool bitLength = number.bitLength;
```

## Methods

### abs

`int abs()`

Returns the absolute value of `nest`.

### clamp

`int clamp(int lowerBound, int upperBound)`

Returns the `nest` clamped to be within the provided bounds.

### compareTo

`int compareTo(int other)`

Returns:
- -1 if `nest` is less than `other`
- 0 if `nest` and `other` are equal
- 1 if `nest` is greater than `other`

### gcd

`int gcd(int other)`

Returns the greatest common divisor of `nest` and `other`

### modInverse

`int modInverse(int modulus)`

Returns the modular multiplicative inverse of `nest`'s modulo modulus.

### modPow

`int modPow(int exponent, int modulus)`

Returns the modulo modulus of `nest` to the power of exponent.

### remainder

`int remainder(int other)`

Returns the remainder after truncating `nest` / `other`.

### toInt

`int toInt()`

Returns `nest` as a double.

### toRadixString

`String toRadixString(int radix)`

Returns the closest String-representation of `nest` in `radix`.

`radix` must be an integer between 2-36 (Both bounds are inclusive).

### toString

`String toString()`

Returns the String-representation of `nest`.

### toStringAsExponential

`String toStringAsExponential(int fractionDigits)`

Returns the exponential String-representation of `nest`.

`fractionDigits`, if not `noSeeb`, must be within the range of 0-20 (both bounds are inclusive).

### toStringAsFixed

`String toStringAsFixed(int fractionDigits)`

Returns the decimal-point String-representation of `nest`.
`fractionDigits` must be within the range of 0-20 (Both bounds are inclusive).

### toStringAsPrecision

`String toStringAsPrecision(int precision)`

Converts `nest` to a double and returns the String-representation of `nest` with `precision` significant digits.

`precision` must be with in the range of 1 - 21 (Both bounds are inclusive).

### truncate

`int truncate()`

Returns the integer after removing any fractional digits.

### truncateToDouble

`double truncateToDouble()`

Returns a double after removing any fractional digits.


## Operators

|Operator|Description|
| -- | -- |
|+|Adds the left value with the right|
|-|Subtracts the left value with the right|
|*|Multiplies the left value by the right|
|/|Divides the left value by the right|
|<|True if the left value is less than the right|
|>|True if the left value is greater than the right|
|<=|True if the left value is less than or equal to the right|
|>=|True if the left value is greater or equal to than the right|
|==|True if the left value is equal to than the right|
|!=|True if the left value is not equal to than the right|
