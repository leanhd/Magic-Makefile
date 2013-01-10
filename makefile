# Author Matthieu Sieben (http://matthieusieben.com)
# Version 23/10/2012
#
# This makefile is licensed under the Creative Commons Attribution
# Partage dans les Mêmes Conditions 2.0 Belgique License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/2.0/be/.
# Use at your own risk.
#
# Use makefile.inc to write you own rules or to overwrite the default values defined here.

SRCDIR  =./src
BINDIR  =./bin

SHELL   =/bin/bash
CC      =/usr/bin/gcc
CFLAGS  =-Wall -Wextra -Werror
LDFLAGS =
LDLIBS  =

# make "all" the default target
.PHONY: default all exec
default: all
all: exec

-include makefile.inc
-include makefile.d

CFLAGS += -I$(SRCDIR)

ifndef DEBUG
DEBUG = 0
endif

ifeq ($(DEBUG), 1)
	CFLAGS += -DDEBUG=1 -ggdb
else
	CFLAGS += -DDEBUG=0 -O2
	LDFLAGS += -O2
endif

.SUFFIXES: .c .o
%.o: %.c
	@echo "  Compiling `basename $<`";
	@$(CC) $(CFLAGS) -o $@ -c $<;

.PHONY: clean
clean:
	@echo "Cleaning compiled files";
	@find $(SRCDIR) -name "*.o" -exec rm {} \;

.PHONY: distclean
distclean: clean
	@echo "Removing executables";
	@find $(BINDIR) -type f -exec rm {} \;
	@[ -e makefile.d ] && rm makefile.d;

$(BINDIR):
	@echo "Creating directory $@";
	@if [ ! -d $@ ]; then mkdir -p $@; fi;

makefile.d: $(shell find $(SRCDIR) -type f -name "*.c")
	@echo "Building dependencies";
	@TEMP_FILE=`mktemp /tmp/makefile.d.XXXXXX`; \
	for file in $^; do  \
		$(CC) $(CFLAGS) -MM -MT $${file/%.c/.o} $$file | tr -d "\\n\\\\" >> $$TEMP_FILE; \
		echo -e "\n" >> $$TEMP_FILE; \
	done; \
	for file in `grep -Hs "main(" $^ | cut -f1 -d':'`; do \
		execname=`basename $$file .c`; \
		objs="$${file/%.c/.o}"; \
		for header in `$(CC) $(CFLAGS) -MM $$file | tr " " "\\n" | grep ".h$$" | sort | uniq | tr "\\n" " "`; do \
			if [ -f $${header/%.h/.c} ]; then \
				objs+=" $${header/%.h/.o}"; \
			fi; \
			for sub_h in `grep "^$${header/%.h/.o}:" $$TEMP_FILE | tr " " "\\n" | grep ".h$$" | tr "\\n" " "`; do \
				if [ -f $${sub_h/%.h/.c} ]; then \
					objs+=" $${sub_h/%.h/.o}"; \
				fi; \
			done; \
		done; \
		objs=`echo -n "$$objs"  | tr " " "\\n" | sort | uniq | tr "\\n" " "`; \
		echo "exec: $$execname" >> $$TEMP_FILE; \
		echo "$$execname: \$$(BINDIR)/$$execname" >> $$TEMP_FILE; \
		echo "\$$(BINDIR)/$$execname: $$objs |\$$(BINDIR)" >> $$TEMP_FILE; \
		echo "	@echo \"Linking $$execname\";" >> $$TEMP_FILE; \
		echo "	@\$$(CC) \$$(LDFLAGS) -o \$$@ $$objs \$$(LDLIBS);" >> $$TEMP_FILE; \
		echo >> $$TEMP_FILE; \
	done; \
	mv $$TEMP_FILE $@; \

ifdef INSTALLDIR

$(INSTALLDIR):
	@echo "Creating directory $@";
	@if [ ! -d $@ ]; then mkdir -p $@; fi;

.PHONY: install install_exec
install: |$(INSTALLDIR)
install: install_exec
install_exec: exec
	@echo "Installing binaries into $(INSTALLDIR)"
	@cp $(BINDIR)/* $(INSTALLDIR)

.PHONY: uninstall uninstall_exec
uninstall: uninstall_exec
uninstall_exec: makefile.d
	@echo "Removing binaries from $(INSTALLDIR)"
	@for f in `$(MAKE) -f makefile.d -pn | grep '^exec:' | cut -d: -f2`; do \
		if [ -f $(INSTALLDIR)/$$f ]; then \
			echo "  Uninstalling $$f"; \
			rm $(INSTALLDIR)/$$f; \
		fi; \
	done;

endif
