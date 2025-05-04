# To track VM snapshots

> NEVER UPGRADE OR UPDATE THE BUILD SYSTEM!!! 

```
graph TD

A[Preparation Finished<br/>(part ii complete)]
B[Binutils Pass 1<br/>installed for initial cc build]
C[GCC Pass 1<br/>installed]
D[Linux Headers<br/>finished]
E[Glibc Pass 1]
F[libstdc++]
G[Toolchain Compilation<br/>finished]
H[Preparing Virtual<br/>Kernel System]

D2[Snapshot cloned<br/>at Linux Headers]


A --> B --> C --> D --> E --> F --> G --> H
D --> D2
```