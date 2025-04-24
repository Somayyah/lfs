	
# 04-13-2025

Finishing Parts i && ii: Preparation & Preparing for the build

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
	
	- What to do:
	
	```
	$ sudo apt install bison gawk texinfo
	$ sudo ln -sf bash /bin/sh
	```
	- Creating a new partition
		- Current layout:
		```
		watari@vbox:~$ sudo fdisk -l
		Disk /dev/loop0: 4 KiB, 4096 bytes, 8 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop1: 73.89 MiB, 77479936 bytes, 151328 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop2: 73.89 MiB, 77475840 bytes, 151320 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop3: 258.04 MiB, 270569472 bytes, 528456 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop4: 11.13 MiB, 11673600 bytes, 22800 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop5: 91.69 MiB, 96141312 bytes, 187776 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop6: 516.01 MiB, 541073408 bytes, 1056784 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop7: 10.77 MiB, 11292672 bytes, 22056 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/sda: 60 GiB, 64424509440 bytes, 125829120 sectors
		Disk model: VBOX HARDDISK   
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes
		Disklabel type: gpt
		Disk identifier: 5BA772D1-BCCC-4CBE-8245-24EE301EE3DB

		Device     Start       End   Sectors Size Type
		/dev/sda1   2048      4095      2048   1M BIOS boot
		/dev/sda2   4096 125827071 125822976  60G Linux filesystem


		Disk /dev/loop8: 10.83 MiB, 11354112 bytes, 22176 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop9: 44.44 MiB, 46596096 bytes, 91008 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop10: 44.45 MiB, 46604288 bytes, 91024 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes


		Disk /dev/loop11: 568 KiB, 581632 bytes, 1136 sectors
		Units: sectors of 1 * 512 = 512 bytes
		Sector size (logical/physical): 512 bytes / 512 bytes
		I/O size (minimum/optimal): 512 bytes / 512 bytes
		watari@vbox:~$ 
		watari@vbox:~$ df -h
		Filesystem      Size  Used Avail Use% Mounted on
		tmpfs           392M  1.5M  391M   1% /run
		/dev/sda2        59G  9.9G   46G  18% /
		tmpfs           2.0G     0  2.0G   0% /dev/shm
		tmpfs           5.0M  8.0K  5.0M   1% /run/lock
		tmpfs           392M  128K  392M   1% /run/user/1000
		/dev/sr0         57M   57M     0 100% /media/watari/VBox_GAs_7.1.4
		watari@vbox:~$ 

		```
		- Creating the partition
		
		Using liveCD image, with GParted I shrank /dev/sda2 to 12 Gigs and created a new partition off the empty space.
		- Creating the filesystem
		```
		mkdir /mnt/lfs
		blkid	### To get the UUID for the new partition
		nano /etc/fstab		### To mount the new filesystem with the line 'UUID="<UUID>"     /mnt/lfs        ext4    defaults        0       0'
		umount -a  ### To mount with the fstab file
		```
		- New layout
		```
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
	- Setting the environment variables

		Listed in env-variables.sh, export to ~/.bash_profile and /root/.bash_profile to persist:
		```
		sudo bash -c 'echo "export LFS=/mnt/lfs" >> /root/.bash_profile'
		```

	- Finishing mounting the fileSystem

		- Creating the mount point
		```
		mkdir -pv $LFS
		mount -v -t ext4 /dev/sda3 $LFS ### Already done from previous steps but just in case
		```
		- Create the convenient partitions
		
		```
		sudo mkdir -vp $LFS/{home,root,opt,tmp,sources,patches,boot/efi,etc,var,tools,usr/{bin,lib,sbin}}
		sudo chmod -v a+wt $LFS/sources
		```

	- Downloading packages and patches
		- Packages
		```
		wget https://raw.githubusercontent.com/Somayyah/lfs/refs/heads/main/get-list-systemd
		wget --input-file=get-list-systemd --continue --directory-prefix=$LFS/sources
		sudo chown root:root $LFS/sources/*
		```
		- Patches
		```
		wget https://raw.githubusercontent.com/Somayyah/lfs/refs/heads/main/get-patches ; sudo mkdir $LFS/patches ; sudo wget --input-file=get-patches --continue --directory-prefix=$LFS/patches ; sudo chown root:root $LFS/patches/*
		```
		- Creating directories heirarchy
		
		```
		# As sudo
		
		mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
		for i in bin lib sbin; do
			ln -sv usr/$i $LFS/$i
		done
		case $(uname -m) in
			x86_64) mkdir -pv $LFS/lib64 ;;
		esac
		```
	- Create the LFS user
		```
		sudo groupadd lfs ; sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
		```
		
		And grant it the necessary privilages
		
		```
		chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
		case $(uname -m) in
			x86_64) chown -v lfs $LFS/lib64 ;;
		esac
		```

	- Set up the environment

		While loging in as lfs:
		```
		cat > ~/.bash_profile << "EOF"
		exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
		EOF
		###
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
		
		```
		[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
		```
		
- Building the LFS Cross Toolchain and Temporary Tools

# 04-24-2025

Finishing part iii: Building the LFS Cross Toolchain and Temporary Tools

- 