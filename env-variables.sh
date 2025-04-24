#!/bin/bash

## Save to ~/.bashrc

## On HOST

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
