# Use this file to define your own rules.

## Overwrite default values

#BINDIR  =./bin/$(shell uname)
#CFLAGS  =-Wall -Werror -pedantic

#PROJECT =my_project
#PROJECT_VERSION=1.0

## Exclude files from the tar / bz2 archives

#EXCLUDES += --exclude "*.tex"

## Setup an installation directory

INSTALLDIR = ~/bin

## Set debugging active by default (use `make DEBUG=0` to overwrite).

#ifndef DEBUG
#DEBUG = 1
#endif

## Add your flags

#LDLIBS += -lpthread
#CFLAGS += -I$(SRCDIR)/includes

## If INSTALLDIR is defined, make install one of the default actions on `make`.

#ifdef INSTALLDIR
#default: install
#endif
