
# Environment variables

## On HOST, Save to ~/.bashrc

export LFS=/mnt/lfs

## On LFS user

export PWD=/home/lfs
export HOME=/home/lfs
export MAKEFLAGS=-j4
export TERM=xterm-256color
export SHLVL=1
export PS1=\u:\w\$ 
export LFS_TGT=x86_64-lfs-linux-gnu
export LC_ALL=POSIX
export LFS=/mnt/lfs
export CONFIG_SITE=/mnt/lfs/usr/share/config.site
export PATH=/mnt/lfs/tools/bin:/usr/bin
export _=/usr/bin/env
export DESTDIR=
export CC_FOR_TARGET=$LFS_TGT-gcc

## In chroot

export CONFIG_SHELL=/bin/bash
export SHELL=/bin/bash
export PATH=/bin:$PATH

# Notable locations and files

- $LFS/tools : To install the cross compiler.
- $LFS/tools/bin : To install the binutils assembler and linker.
- $LFS/tools/$LFS_TGT/bin : To install the binutils assembler and linker.
- /etc/inittab : To control the init program which is important in the boot process in SystemV
- /etc/udev/rules.d, /usr/lib/udev/rules.d, /run/udev/rules.d : contain udev rules that define how udev processes device events (uevents), including setting device permissions, ownership, names, and creating symlinks.

# Important commands

```

# NOTE: Remove the prefix $LFS_TGT- to use the commands as sudoer, for example:

	ld --verbose | grep SEARCH	

# As lfs

	## After you set up the cross-compilation toolchain. To illustrate the current search paths and their order 

	$LFS_TGT-ld --verbose | grep SEARCH

	## To find out which standard linker gcc will use
	
	$LFS_TGT-gcc -print-prog-name=ld
	
	## show detailed information about the preprocessor, compilation, assembly stages including gcc's search paths for included headers and their
order. 
	$LFS_TGT-gcc -v example.c
	
# As Sudoer

```
