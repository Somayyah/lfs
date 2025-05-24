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
	

## 04-26-2025

### log

- I continued compiling hte rest of the packages from chapters 5 and 6, I had to restart after libstdc++ as I made the mistake of using the pre extracted tarbal from a previous compilation instead of unpacking a real one.

## 05-03-2025

### log

- Until Section 7.4, “Entering the Chroot Environment”, the commands must be run as root, with the LFS variable set.
After entering chroot, all commands are run as root, fortunately without access to the OS of the computer you built
LFS on. Be careful anyway, as it is easy to destroy the whole LFS system with bad commands.

- 
```
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac

mkdir -pv $LFS/{dev,proc,sys,run}

mount -v --bind /dev $LFS/dev

mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
```

## 05-04-2025

### log

- 

```
chroot "$LFS" /usr/bin/env -i \
HOME=/root \
TERM="$TERM" \
PS1='(lfs chroot) \u:\w\$ ' \
PATH=/usr/bin:/usr/sbin \
MAKEFLAGS="-j$(nproc)" \
TESTSUITEFLAGS="-j$(nproc)" \
/bin/bash --login
```

and it's not working...

I cloned the snapshot **Linux Headers finished** to trace back my steps while keeping the latest snapshots, this way I can troubleshoot the issue while allowing myself to progress. It's a storage eater though, hopefully I get to delete the snapshots for good after I chroot.

#### Snapshot cloned at Linux Headers

- glibc

```
case $(uname -m) in
i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
;;
x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
;;
esac
```

And immediately got permission denied:

```
lfs:/mnt/lfs/sources$ tar -xf glibc-2.40.tar.xz 
lfs:/mnt/lfs/sources$ cd glibc-2.40
lfs:/mnt/lfs/sources/glibc-2.40$ case $(uname -m) in
i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
;;
x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
;;
esac
ln: failed to create symbolic link '/mnt/lfs/lib64': Permission denied
ln: failed to create symbolic link '/mnt/lfs/lib64/ld-lsb-x86-64.so.3': No such file or directory
lfs:/mnt/lfs/sources/glibc-2.40$ 

```

I'm logged in as lfs so why is this happening? I already install the previous packages without issues and this has never happened prior to cloning the snapshot! Let's retrace:

Important notes for each package:

- Using the tar program, extract the package to be built ==> ✅
- In Chapter 5 and Chapter 6, ensure you are the lfs user when extracting the package. ==> ✅ I'm on chapter 5, since I get permission denied maybe I need to reconfigure the user's permissions
- Do not use any method except the tar command to extract the source code. ==> ✅ 
- Using the cp -R command to copy the source code tree somewhere else can destroy timestamps in the source tree, and cause the build to fail. ==> ✅ 
- Change to the directory created when the package was extracted. ==> ✅ 
- Follow the instructions for building the package. ==> ✅ 
- Change back to the sources directory when the build is complete. ==> ✅ 
- Delete the extracted source directory unless instructed otherwise. ==> ✅ 
	
The lfs user permissions and privilages are configured this way:

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
  
  will redo and try again, let's see..
  
  Same error.. But wait, I remember from the previous attempt that $LFS/lib64 shouldn't exist:

	> The LFS editors have deliberately decided not to use a /usr/lib64 directory. Several steps are taken to be
	> sure the toolchain will not use it. If for any reason this directory appears (either because you made an error
	> in following the instructions, or because you installed a binary package that created it after finishing LFS), 
	> it may break your system. You should always be sure this directory does not exist.

  and I remember that I created other symlinks. So is this behavior expected? if yes, does that mean my attempt at pointing the symlinks to $LFS/lib instead of $LFS/lib64 was the reason for chroot failure? The plot thickens... How to approach further hmmm....
  
  I decided to just proceed without creating the symlinks as below:
  
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
  ```
  worse case scenario is I'll go a previous snapshot. Let's continue:
  
  ```
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
  
  Now we finish the sanity check:
  
  ```
	lfs:/mnt/lfs/sources/glibc-2.40/build$ echo 'int main(){}' | $LFS_TGT-gcc -xc -
	lfs:/mnt/lfs/sources/glibc-2.40/build$ readelf -l a.out | grep ld-linux
		  [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
	lfs:/mnt/lfs/sources/glibc-2.40/build$ rm -v a.out
	removed 'a.out'
	lfs:/mnt/lfs/sources/glibc-2.40/build$ 
  ```
  
  I'll proceed even with /lib64 in the output.. hopefully I don't get humbled again. Moving on to the rest of the packages..
  
## 05-05-2025

### log

- I failed again.. need to check further. Why what's going on...

```
-bash-5.2# file /usr/bin/env
/usr/bin/env: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=bf98920296e7b490882f624f8c16424819dcf4a9, for GNU/Linux 3.2.0, stripped
-bash-5.2# file $LFS/usr/bin/env
/mnt/lfs/usr/bin/env: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 4.19.0, with debug_info, not stripped
-bash-5.2# ls -l $lfs/lib64/ld-linux-x86-64.so.2
lrwxrwxrwx 1 root root 44 Jan 28 20:07 /lib64/ld-linux-x86-64.so.2 -> ../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
-bash-5.2# 
```

$LFS/usr/bin/env uses the interpretter /lib64/ld-linux-x86-64.so.2, which is a symlinkt to ../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2, when I try to view it:

```
-bash-5.2# ls $LFS/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
ls: cannot access '/mnt/lfs/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2': No such file or directory
-bash-5.2# 
-bash-5.2# find $LFS -name 'ld-linux-x86-64.so.2'
/mnt/lfs/usr/lib/ld-linux-x86-64.so.2
-bash-5.2# 
```

It exists in $LFS/usr/lib so will update the symlink and see how it goes:

```
rm $LFS/lib64/ld-linux-x86-64.so.2
ln -sv ../usr/lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-linux-x86-64.so.2
```

and it failed:

```
-bash-5.2# ln -sv ../usr/lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-linux-x86-64.so.2
ln: failed to create symbolic link '/mnt/lfs/lib64/ld-linux-x86-64.so.2': No such file or directory
-bash-5.2# 

```

What if I just...create the /lib64 directory? what's the worse that could happen? I can go back and recompile again but for now I need some progress >:(

```
mkdir -pv $LFS/lib64
ln -sv ../usr/lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-linux-x86-64.so.2
```

Now we get a new error so that's a good sign:

```
-bash-5.2# chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin MAKEFLAGS="-j$(nproc)" TESTSUITEFLAGS="-j$(nproc)" /bin/bash --login
/usr/bin/env: '/bin/bash': No such file or directory
-bash-5.2# 
```

so let's make a new Symlink:

```
ln -sv /usr/bin/bash $LFS/bin/bash
```

or wait I have a bash installed in LFS:

```
-bash-5.2# find $LFS -name 'bash'
/mnt/lfs/usr/lib/bash
/mnt/lfs/usr/include/bash
/mnt/lfs/usr/share/doc/bash
/mnt/lfs/usr/bin/bash
-bash-5.2# 
```

So will try to run ```chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin MAKEFLAGS="-j$(nproc)" TESTSUITEFLAGS="-j$(nproc)" /usr/bin/bash --login```

Tada!! Since we don't have /etc/shadow yet it's expected for the prompt to be like this:

```
(lfs chroot) I have no name!:/#
```

Now we proceed with creating the rest of the chapter all inside chroot:

```
mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1 localhost $(hostname)
::1 localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF
```

## 05-06-2025

### log

- gettext

```
tar -xvf Gettext-0.22.5.tar.gz

cd gettext-0.22.5

./configure --disable-shared

```

configuration fails, reason is configure file doesn't exist:

```
"gettext" "bash: ./configure: cannot execute: required file not found"
```

Yet the file exists and is an excutable:

```
ls -l configure
-rwxrwxr-x 1 root root 139265 Apr 06  2025 configure
```

and it has the correct shebang:

```
head -n 1 configure
#! /bin/sh
```

/bin/sh exists but it has a broken link:

```
(lfs chroot) root:/sources/gettext-0.22.5# ls -l /bin/sh
lrwxrwxrwx 1 root root 4 May  6 07:48 /bin/sh -> bash
(lfs chroot) root:/sources/gettext-0.22.5# 

file /bin/sh
/bin/sh: broken symbolic link to bash
```

since I know that /usr/bin/bash exists I did below:

```
cp -v /usr/bin/bash /bin/
ln -svf bash /bin/sh
```

now configure runs fine. with make I get this:

```
gcc -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -g -O2 -w -fno-analyzer -c gl_array_list.c
/bin/sh: line 25: sh: command not found
gcc -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -g -O2 -w -fno-analyzer -c basename-lgpl.c
/bin/sh: line 25: sh: command not found
gcc -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -g -O2 -w -fno-analyzer -c binary-io.c
/bin/sh: line 25: sh: command not found
gcc -DHAVE_CONFIG_H -I. -I..  -I. -I. -I.. -I.. -Iglib -DIN_LIBTEXTSTYLE -DLIBXML_STATIC    -I./libcroco  -DDEPENDS_ON_LIBICONV=1   -g -O2 -w -fno-analyzer -c c-ctype.c
/bin/sh: line 25: sh: command not found
```

because the shell cannot find the sh command even when it exists in /bin:

```
(lfs chroot) root:/sources/gettext-0.22.5# sh -c "echo hello"
sh: sh: command not found
(lfs chroot) root:/sources/gettext-0.22.5# echo $PATH
/usr/bin:/usr/sbin
(lfs chroot) root:/sources/gettext-0.22.5# /bin/sh -c "echo hi"
hi
(lfs chroot) root:/sources/gettext-0.22.5# 
```

This means the issue is because the PATH variable isn't updated, after updating it the issue went away:

```
(lfs chroot) root:/sources/gettext-0.22.5# echo $PATH
/usr/bin:/usr/sbin
(lfs chroot) root:/sources/gettext-0.22.5# export PATH=/bin:$PATH
(lfs chroot) root:/sources/bison-3.8.2# sh -c "echo hi"
hi
```

and now make runs without issues.

**PART III FINISHED, INTO PART IV - BUILDING THE LFS SYSTEM**

## 05-11-2025

### log

- While compiling binutils, I encountered 125 failures after running ```make -k check``` which seems a lot. However as per the book:

```
Twelve tests fail in the gold test suite when the --enable-default-pie and --enable-default-ssp options are passed
to GCC.
```

Since we already have 12 failures then we are safe...

```
(lfs chroot) root:/sources/binutils-2.43.1/build# grep '^FAIL:' $(find -name '*.log') | grep gold | wc
     12      24     635
(lfs chroot) root:/sources/binutils-2.43.1/build# 
```

## 05-13-2025

### Log

- For the expat package in the book the download link is for the version 2.6.2.tar.xz but in the instructions its 2.6.4.

## 05-14-2025

### Log

- Finally Chapter 8 is done, onto Chapter 9.

## 05-15-2025

### Log

- SystemV is the classic Unix boot system. It uses ```Init``` to set basic processes like login via getty. It runs a script usually called rc which controls other scripts to initialize the system. ```init``` program is controlled by /etc/inittab, it controls the boot levels and can be edited:

```
0 — halt
1 — Single user mode
2 — User definable
3 — Full multiuser mode
4 — User definable
5 — Full multiuser mode with display manager 
6 — reboot
```

3 & 5 are default run levels.

## 05-16-2025

### Log

- There are two methods for device handling in Linux:

**Static device creation** were thousands of device nodes are created even if they don't exist. This is done via **MAKEDEV** script, it calls for **mknod** program with relevant major / minor numbers of all devices that exist.
With **UDEV**, device nodes are managed dynamically. During early boot, the kernel creates basic nodes in /dev using devtmpfs Later, udevd starts in userspace to and remove or edit those nodes with names, permissions, and symlinks.

Device nodes don't require much space in the memory.

- devfs (RIP) was deprecated due to issues like race condition issues. Then comes sysfs.

- Udev implementation:
	- sysfs: Drivers that have been compiled into the kernel register their object in sysfs internally while being detected by the kernel. Drivers that are compiled as modules get regitered once loaded. Drivers data becomes available once sysfs is mounted onto /sys, now the drivers are available to the userspace and udevd for processing.
	
	- devtmpfs: Used for the device files which are created by the kernel upon boot. Any driver that wishes to register a device node can use devtmpfs via driver core to do it. devtmpfs is mounted on /dev then the device node is exposed to the userspace with a fixed set of permissions.
	
	- /sys is a view into the kernel’s internal object tree, /dev is where the actual device files (nodes) live, udevd listens to kernel uevents via netlink, uses /sys to read device metadata, and updates /dev accordingly. devtmpfs gives you basic /dev nodes early during boot. udev builds on that, adds logic, symlinks, permissions .. etc.
	
	- udev listens to kernel events monitoring for new or removed devices, reads from /sys to understand the layout, creates and modifies nodes in the /dev and updates permissions, symlinks ... etc.
	
	- What happens when USB is plugged?
	
		- Hardware gets plugged and detected by the Kernel.
		- Kernel sends event and catched by udevd then looks into /sys to get information like vendor,type .. etc
		- udevd then creates a new node in /dev for this device and sets permissions.
		
	- What happens during boot?
		- Kernel detects hardware and registers it internally.
		- Kernel mounts devtmpfs on /dev and creates basic device nodes there.
		- Once userspace starts, udevd begins listening to device events.
		- udev modifies /dev entries: applies names, symlinks, permissions, and handles hotplugged devices (like USB).

	- Module loading:
		- Device appears → kernel posts modalias → udev sees MODALIAS → runs modprobe → module(s) with matching alias get loaded.
		- Potential problems:
			- A Kernel Module Is Not Loaded Automatically
			- A Kernel Module Is Not Loaded Automatically, and Udev Is Not Intended to Load It
			- Udev Loads Some Unwanted Module
			- Udev Creates a Device Incorrectly, or Makes the Wrong Symlink
			- Udev Rule Works Unreliably
			- Udev Does Not Create a Device
			- Device Naming Order Changes Randomly After Rebooting
			
## 05-21-2025

### Log

**Compiling the kernel** : No customization instead I'll follow the book exactly as it is.

**Finally finished LFS** and now it's time to reboot, and it's not working:

```
Booting 'GNU/Linux, Linux 6.10.5-lfs-12.2'

error: file '/boot/vmlinuz-6.10.5-lfs-12.2' not found.
Press any key to continue...

Failed to boot both default and fallback entries.
Press any key to continue...
```

We go back to the boot menu and enter c to enter the grub cli and hunt the boot directory:

```
grub> ls
grub> (hd0,gpt3) (hd0.gpt2) (hd0.gpt1)
grub> ls (hd0)/
error: unknown filesystem.
grub> ls (hd0,gpt3)/
lost+found/ home/ root/ boot/ opt/ tmp/ sources/ patches/ bin/ usr/ var/ lib/ e
tc/ sbin/ dev/ proc/ sys/ run/ lib64/ mnt/ srv/ media/
grub> ls (hd0,gpt2)/
lost+found/ bin lib lib64 bin.user-is-merged boot cdrom/ dev/ etc/ home/
lib.user.is-merged media/ mnt/ opt/ proc/ root/ run/ sbin/ usr.user-is-merged/ snap/
srv/ sys/ tmp/ usr/ var/ swap.img
grub> ls (hd0,gpt3)/boot/
efi/ vmlinuz-6.10.5-lfs-12.2 System.map-6.10.5 config-6.10.5 grub/
grub>
```

There it is, I searched the internet and found below commands which enables us to manually boot into vmlinuz-6.10.5-lfs-12.2:

```
set root=(hd0,gpt3)
linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda3 ro
boot
```

and now it's working!!!

```
<lfs> login: 
```

Login into root isn't working which is weird, instead of going into a previous snapshot and reset the password which I'm sure I did I'll try again but add /bin/bash as the login shell:

```
set root=(hd0,gpt3)
linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda3 ro init=/bin/bash
boot
```

then set the password again with ```passwd``` but it didn't work:

```
bash-5.2# passwd root
Changing password for root
Enter the new password (minimum of 5 characters)
Please use a combination of upper and lower case letters and numbers.
The password for root is unchanged.
bash-5.2# passwd
Enter the new password (minimum of 5 characters)
Please use a combination of upper and lower case letters and numbers.
The password for root is unchanged.
bash-5.2# passwd
```

I tried booting without the ``ro`` option but with no luck. then I tried from bash to just delete it:

```
passwd -d root
```

I'll add it later.

**LFS complete**

## Next steps

– Automate kernel boot via GRUB config
– Set secure root password
– Begin BLFS to expand the system

---

## Fixing the password issue

I can't log into the OS without using ```init=/bin/bash```, the below output shows the account without a password so why can't I still log in?

```
bash-5.2# passwd -S
root NP 2026-05-11 0 99999 7 -1
bash-5.2#
```

I tried to use the soft keyboard in VBOX but with no luck. I feel like this has to do with the keyboard, tty but not sure. I checked the grub.cfg under /dev/sda3 which is the partition for LFS and I sense there's some misconfiguration:

```
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5
insmod part_gpt
insmod ext2
set root=(hd0,2)
menuentry "GNU/Linux, Linux 6.10.5-lfs-12.2" {
    linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda2 ro
}
```

It should be root=/dev/sda3 not /dev/sda2. Let's boot again with the bash shell and fix it, let's see:

```
set root=(hd0,gpt3)
linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda3 ro init=/bin/bash
boot
```

Not sure if it will fix the root login issue but it feels wrong to be like this. Vim is installed on the LFS system so this is good but I cound't edit the grub.cfg file becuase it's in read only mode, so I entered the command:

```
mount -o remount,rw /
```

then the editing was successful. Now let's try again.. **It didn't work** but wait, this line in grub.cfg seems wrong:

```
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5
insmod part_gpt
insmod ext2
set root=(hd0,2)
menuentry "GNU/Linux, Linux 6.10.5-lfs-12.2" {
    linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda3 ro
}
```

I know for a fact that LFS lives in (hd0,gpt3), will try to edit it again, let's see.

Alright so the boot issue is now fixed, I no longer have to manually boot via the grub CLI but the root password isn't fixed yet.