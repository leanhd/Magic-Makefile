# Use this file to define your own rules.

## Overwrite default values

#BINDIR  =./bin/$(shell uname)
#CFLAGS  =-Wall -Werror -pedantic

#PROJECT =my_project
#PROJECT_VERSION=1.0

## Exclude files from the tar / bz2 archives

EXCLUDES += --exclude "*.bak"

## Setup a default installation directory (use `make install PREFIX=/my/path` to overwrite).

ifndef PREFIX
PREFIX = /usr/local
endif

## Set debugging active by default (use `make DEBUG=0` to overwrite).

#ifndef DEBUG
#DEBUG = 1
#endif

## If you which to avoid installing you test binaries, you may define the name of the executable you which to install

#INSTALL_BINARIES = my_main_bin

## Add specific flags

#LDLIBS += -lpthread
#CFLAGS += -I$(SRCDIR)/includes
