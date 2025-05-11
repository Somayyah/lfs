# To track VM snapshots

> NEVER UPGRADE OR UPDATE THE BUILD SYSTEM!!! 

```mermaid
flowchart TD;
    A["Preparation Finished (part ii complete)"]
    B["Binutils Pass 1 installed for initial cc build"]
    C["GCC Pass 1 installed"]
    D["Linux Headers finished"]
    E["Glibc Pass 1"]
    F["libstdc++"]
    G["Toolchain Compilation finished"]
    H["Preparing Virtual Kernel System"]

    D2["gcc-phase2 make done"]
	E2["gcc compiled"]
	F2["into chroot"]
	G2["iii - 7.13.1 - Cleaning"]
	H2["IV - Into Glibc"]
	I2["IV - Into Glibc done"]
	J2["IV - Into bc"]
	K2["IV - Into expect5"]
	L2["IV - Into binutils"]
	M2["IV - Into GMP"]
	
	
	
    A --> B --> C --> D --> E --> F --> G --> H;
    D --> D2 --> E2 --> F2 --> G2 --> H2 --> I2 --> J2 --> K2 --> L2 --> M2;
```