# Finishing Parts I & II: Preparation & Preparing for the Build

## 04-13-2025

### Log

- **Created the VM, preparing.**
  - **version-check.sh**
    ```bash
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

  - **What to do:**
    ```bash
    $ sudo apt install bison gawk texinfo
    $ sudo ln -sf bash /bin/sh
    ```

- **Creating a new partition**
  - **Current layout:**
    ```bash
    watari@vbox:~$ sudo fdisk -l
    Disk /dev/loop0: 4 KiB, 4096 bytes, 8 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    ...
    ```

  - **Creating the partition**
    Using liveCD image, with GParted, I shrank `/dev/sda2` to 12 GB and created a new partition off the empty space.

  - **Creating the filesystem**
    ```bash
    mkdir /mnt/lfs
    blkid  # To get the UUID for the new partition
    nano /etc/fstab  # To mount the new filesystem with the line 'UUID="<UUID>"     /mnt/lfs        ext4    defaults        0       0'
    umount -a  # To mount with the fstab file
    ```

  - **New layout**
    ```bash
    watari@vbox:~$ df -h
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           392M  1.5M  391M   1% /run
    /dev/sda2        13G  9.9G  2.0G  84% /
    tmpfs           2.0G     0  2.0G   0% /dev/shm
    tmpfs           5.0M  8.0K  5.0M   1% /run/lock
    tmpfs           392M  128K  392M   1% /run/user/1000
    /dev/sr1         57M   57M     0 100% /media/watari/VBox_GAs_7.1.4
    /dev/sda3        46G   24K   44G   1% /mnt/lfs
    ```

- **Setting the environment variables**
  Listed in `env-variables.sh`, export to `~/.bash_profile` and `/root/.bash_profile` to persist:
  ```bash
  sudo bash -c 'echo "export LFS=/mnt/lfs" >> /root/.bash_profile'
  ```

- **Finishing mounting the filesystem**
  - **Creating the mount point**
    ```bash
    mkdir -pv $LFS
    mount -v -t ext4 /dev/sda3 $LFS  # Already done from previous steps but just in case
    ```

  - **Create the convenient partitions**
    ```bash
    sudo mkdir -vp $LFS/{home,root,opt,tmp,sources,patches,boot/efi,etc,var,tools,usr/{bin,lib,sbin}}
    sudo chmod -v a+wt $LFS/sources
    ```

- **Downloading packages and patches**
  - **Packages**
    ```bash
    wget https://raw.githubusercontent.com/Somayyah/lfs/refs/heads/main/get-list-systemd
    wget --input-file=get-list-systemd --continue --directory-prefix=$LFS/sources
    sudo chown root:root $LFS/sources/*
    ```

  - **Patches**
    ```bash
    wget https://raw.githubusercontent.com/Somayyah/lfs/refs/heads/main/get-patches
    sudo mkdir $LFS/patches
    sudo wget --input-file=get-patches --continue --directory-prefix=$LFS/patches
    sudo chown root:root $LFS/patches/*
    ```

  - **Creating directory hierarchy**
    ```bash
    mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
    for i in bin lib sbin; do
        ln -sv usr/$i $LFS/$i
    done
    case $(uname -m) in
        x86_64) mkdir -pv $LFS/lib64 ;;
    esac
    ```

- **Create the LFS user**
  ```bash
  sudo groupadd lfs
  sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
  ```
  And grant it the necessary privileges:
  ```bash
  chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools} 
  case $(uname -m) in
      x86_64) chown -v lfs $LFS/lib64 ;;
  esac
  ```

- **Set up the environment**
  While logging in as `lfs`:
  ```bash
  cat > ~/.bash_profile << "EOF"
  exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
  EOF

  cat > ~/.bashrc << "EOF"
  set +h
  umask 022
  LFS=/mnt/lfs
  LC_ALL=POSIX
  LFS_TGT=$(uname -m)-lfs-linux-gnu
  PATH=/usr/bin
  if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
  PATH=$LFS/tools/bin:$PATH
  CONFIG_SITE=$LFS/usr/share/config.site
  export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
  EOF

  source ~/.bash_profile
  ```

  As root:
  ```bash
  [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
  ```

---

# Finishing Part III: Building the LFS Cross Toolchain and Temporary Tools

## 04-24-2025

Divided into three stages:
1. Building a cross compiler and its associated libraries.
2. Using this cross toolchain to build several utilities in a way that isolates them from the host distribution.
3. Entering the chroot environment (which further improves host isolation) and constructing the remaining tools needed to build the final system.

### Taxonomy

- **Cross compilation**: The process of building software on one platform (the build host) that is intended to run on a different platform (the target system).
- **The build**: The machine where we build programs. Note that this machine is also referred to as the “host.”
- **The host**: The machine/system where the built programs will run. Note that this use of “host” is not the same as in other sections.
- **The target**: Only used for compilers. It is the machine the compiler produces code for. It may be different from both the build and the host.

### Log

- **Let's figure out the system triplet for the build machine:**
  ```bash
  watari@vbox:~$ gcc -dumpmachine
  x86_64-linux-gnu
  watari@vbox:~$
  ```

  For the host system:
  ```bash
  lfs:~$ gcc -dumpmachine
  x86_64-linux-gnu
  lfs:~$
  ```

  I'll track all the system triplet changes in `system_triplet.md`. I'll replace "Build, host, target" with "Host, staging, target" because it's less confusing to me.

- We can't build `glibc` without a working compiler, and can’t have a fully functional compiler without a functional version of `libgcc`. So, we build a minimal version of `libgcc` to get started, use it to build `glibc`, and then finish the job by building the fully functional `libgcc` and `libstdc++`. The cross compiler will be installed in `$LFS/tools`.

- **Cross Compiler Toolchain Build Order:**

  **Initial Toolchain (Stage 1):**
  `binutils` → `gcc` (temporary minimal compiler just enough to build `glibc`) → `sanitized Linux API headers` (so `glibc` knows what kernel features exist) → `glibc` (the target system’s C library) → `libstdc++` (C++ standard library, part of GCC, built after `glibc` since it needs a working C library).

  **Rebuild Phase (Stage 2):**
  Once we have a working `glibc`, we rebuild everything to eliminate reliance on the host system:
  `binutils` (recompiled against the new `glibc`, installed into `$LFS/tools`) → `gcc` (rebuilt to use the new `glibc`, to produce binaries fully independent from the host).

  Stage 2 includes a proper build of `libstdc++`, now fully functional, with support for threading, exceptions, and linked correctly to the new `glibc`.

- By default, gcc points at cc in the host instead of the lfs system, as the variable CC_FOR_TARGET is set to the host's cc. It assumes that since the target and the host have the same architecture, then we are compiling natively. So we need to explicitly tell GCC to use CC_FOR_TARGET=$LFS_TGT-gcc instead.
	
- When building packages in LFS:

- **Patches** are only applied if there's an actual problem to fix.
- It's ok to see **offset** or **fuzz** warnings while patching.
- During compilation, you may encounter **warnings** about deprecated C/C++ syntax. That’s normal.

**Important** : Before proceeding read the notes in page 44.

## 04-25-2025

### log 

- Important notes for each package:
	a. Using the tar program, extract the package to be built. 
	b. In Chapter 5 and Chapter 6, ensure you are the lfs user when extracting the package. 
	c. Do not use any method except the tar command to extract the source code. 
	d. Using the cp -R command to copy the source code tree somewhere else can destroy timestamps in the source tree, and cause the build to fail.
	e. Change to the directory created when the package was extracted.
	f. Follow the instructions for building the package.
	g. Change back to the sources directory when the build is complete.
	h. Delete the extracted source directory unless instructed otherwise.

- Binutlis-pass1

	```
	su - lfs
	cd $LFS/sources
	tar -xf binutils-2.43.1.tar.xz
	cd binutils-2.43.1
	mkdir -v build ; cd build
	../configure --prefix=$LFS/tools \
		--with-sysroot=$LFS \
		--target=$LFS_TGT \
		--disable-nls \
		--enable-gprofng=no \
		--disable-werror \
		--enable-new-dtags \
		--enable-default-hash-style=gnu
	make & make install
	```
- gcc

	```
	# requires the GMP, MPFR and MPC packages
	tar -xf gcc-14.2.0.tar.xz ; cd gcc-14.2.0
	tar -xf ../mpfr-4.2.1.tar.xz     
	mv -v mpfr-4.2.1 mpfr       
	tar -xf ../gmp-6.3.0.tar.xz 
	mv -v gmp-6.3.0/ gmp
	tar -xf ../mpc-1.3.1.tar.gz 
	mv -v mpc-1.3.1/ mpc
	case $(uname -m) in
		x86_64)
			sed -e '/m64=/s/lib64/lib/' \
				-i.orig gcc/config/i386/t-linux64
		;;
	esac
	mkdir -v build ; cd build
	../configure \
		--target=$LFS_TGT \
		--prefix=$LFS/tools \
		--with-glibc-version=2.40 \
		--with-sysroot=$LFS \
		--with-newlib \
		--without-headers \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-threads \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--enable-languages=c,c++
	make & make install
	cd ..
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
		`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
	```
- Linux API headers
	
	```
	tar -xf linux-6.10.5.tar.xz 
	cd linux-6.10.5
	make mrproper
	make headers 
	find usr/include -type f ! -name '*.h' -delete 
	cp -rv usr/include $LFS/usr
	```
	
	**I had to redo this step as I did the first commands as the original sudoer user not lfs, luckily I had the snapshot ready to revert back**

- glibc-pass1

	GCC is the compiler for C and C++. It ships with the C++ standard library (libstdc++), but not glibc. glibc is the C standard library and must be compiled separately. GCC depends on glibc to function fully, especially for linking and runtime support. That’s why we compile a temporary GCC first, then glibc, then a final GCC that uses the real glibc and builds the full libstdc++.

	The book states to create $LFS/lib64 symlinks as below:

	```
	case $(uname -m) in
		i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
		;;
		x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
			ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
		;;
	esac
	```
	
	But we have this note in part ii:
	
	> The LFS editors have deliberately decided not to use a /usr/lib64 directory. Several steps are taken to be
	> sure the toolchain will not use it. If for any reason this directory appears (either because you made an error
	> in following the instructions, or because you installed a binary package that created it after finishing LFS), 
	> it may break your system. You should always be sure this directory does not exist.
	
	So instead I'll try using $LFS/lib instead:
	
	```
	case $(uname -m) in
	i?86) 
	   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
	   ;;
	x86_64) 
	   ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib
	   ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib/ld-lsb-x86-64.so.3
	   ;;
	esac
	patch -Np1 -i ../../patches/glibc-2.40-fhs-1.patch
	mkdir -v build & cd build
	echo "rootsbindir=/usr/sbin" > configparms
	../configure \
		--prefix=/usr \
		--host=$LFS_TGT \
		--build=$(../scripts/config.guess) \
		--enable-kernel=4.19 \
		--with-headers=$LFS/usr/include \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib
	make
	make DESTDIR=$LFS install
	sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
	```
	
	Let's perform sanity check:
	
	```
	echo 'int main(){}' | $LFS_TGT-gcc -xc -
	readelf -l a.out | grep ld-linux
	```
	
	Expected output
	
	```
	[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
	```
	
	Once all is well, clean up the test file:
	```
	rm -v a.out
	```
	
- Libstdc++ from GCC-14.2.0

	```
	cd gcc-14.2.0
	mkdir -v build & cd build
	../libstdc++-v3/configure \
		--host=$LFS_TGT \
		--build=$(../config.guess) \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
	make 
	make DESTDIR=$LFS install
	rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
	```
	
- Cross Compiling Temporary Tools

	- M4-1.4.19
	
	```
	tar -xf M4-1.4.19.tar.gz
	cd M4-1.4.19
	./configure --prefix=/usr \
		--host=$LFS_TGT \
		--build=$(build-aux/config.guess)
	make
	make DESTDIR=$LFS install
	
	```