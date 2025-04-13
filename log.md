	
# 04-13-2025

- Created the VM, preparing.
	- ✅ version-check.sh
	```
	watari@vbox:~$ bash version-check.sh 
	OK:    Coreutils 9.4    >= 8.1
	OK:    Bash      5.2.21 >= 3.2
	OK:    Binutils  2.42   >= 2.13.1
	ERROR: Cannot find bison (Bison)
	OK:    Diffutils 3.10   >= 2.8.1
	OK:    Findutils 4.9.0  >= 4.2.31
	ERROR: Cannot find gawk (Gawk)
	OK:    GCC       13.3.0 >= 5.2
	OK:    GCC (C++) 13.3.0 >= 5.2
	OK:    Grep      3.11   >= 2.5.1a
	OK:    Gzip      1.12   >= 1.3.12
	ERROR: Cannot find m4 (M4)
	OK:    Make      4.3    >= 4.0
	OK:    Patch     2.7.6  >= 2.5.4
	OK:    Perl      5.38.2 >= 5.8.8
	OK:    Python    3.12.3 >= 3.4
	OK:    Sed       4.9    >= 4.1.5
	OK:    Tar       1.35   >= 1.22
	ERROR: Cannot find texi2any (Texinfo)
	OK:    Xz        5.4.5  >= 5.0.0
	OK:    Linux Kernel 6.11.0 >= 5.4
	OK:    Linux Kernel supports UNIX 98 PTY
	Aliases:
	ERROR: awk  is NOT GNU
	ERROR: yacc is NOT Bison
	ERROR: sh   is NOT Bash
	Compiler check:
	OK:    g++ works
	OK: nproc reports 4 logical cores are available
	watari@vbox:~$ 
	```
	
	What to do:
	
	```
	$ sudo apt install bison gawk texinfo
	$ sudo ln -sf bash /bin/sh
	```
	- 