# Binary Lambda Calculus Virtual Machine

`blc` implements Tromp's binary lambda calculus virtual machine in
assembly. This lets us replace `calloc()` with `push`. That enables it
to run faster and use less memory. Read <https://justine.lol/lambda/>
for further details.
