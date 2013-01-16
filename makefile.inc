# Use this file to define your own rules.

## Overwrite default values

#BINDIR  =./bin/$(shell uname)
#CFLAGS  =-Wall -Werror -pedantic

#PROJECT =my_project
#PROJECT_VERSION=1.0

## Exclude files from the tar / bz2 archives

#EXCLUDES += --exclude "*.tex"

## Change the installation directory (use `make DESTDIR=/my/path` to overwrite).

ifndef DESTDIR
DESTDIR = ~
endif

## Set debugging active by default (use `make DEBUG=0` to overwrite).

#ifndef DEBUG
#DEBUG = 1
#endif

## Add your flags

#LDLIBS += -lpthread
#CFLAGS += -I$(SRCDIR)/includes
