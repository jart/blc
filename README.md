# Binary Lambda Calculus Virtual Machine

`blc` implements Tromp's original IOCCC binary lambda calculus virtual
machine in assembly. This lets us replace `calloc()` with `push`. That
enables it to run faster and use less memory. Read
<https://justine.lol/lambda/> for further details.

## Build Instructions

You may install `blc` as follows on any Linux AMD64 computer:

```sh
make
doas make install PREFIX=/usr/local
```

## Example Programs

Here's how to print an ASCII diagram of a Hilbert space filling curve:

```sh
{ cat prog/hilbert.blc; printf 123; } | blc
```
