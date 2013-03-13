# Author Matthieu Sieben (http://matthieusieben.com)
# Version 23/10/2012
#
# This makefile is licensed under the Creative Commons Attribution
# Partage dans les Mêmes Conditions 2.0 Belgique License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/2.0/be/.
# Use at your own risk.
#
# Use makefile.inc to write you own rules or to overwrite the default values defined here.

PROJECT  = $(shell basename "`realpath $(CURDIR)`")
PROJECT_VERSION = 1.0

SRCDIR   = ./src
BINDIR   = ./bin

SHELL    = /bin/bash
CC       = /usr/bin/gcc
CFLAGS   = -Wall -Wextra -Werror
LDFLAGS  =

EXCLUDES = --exclude "*~" --exclude ".*"

# Phony rules
.PHONY: deps
.PHONY: default all exec clean
.PHONY: dist distclean tar bz2
.PHONY: install install_exec uninstall uninstall_exec

# Make "all" the default target.
default: all
all: exec

# Inculde additionnal rules
-include makefile.inc
-include makefile.d

# Debugging is disabled by default
ifndef DEBUG
DEBUG = 0
endif

# Setup C flags
ifneq ($(DEBUG), 0)
	CFLAGS  += -ggdb -DDEBUG=$(DEBUG)
else
	CFLAGS  += -O2 -DDEBUG=0
	LDFLAGS += -O2
endif

## Common macros

empty		=
comma		= ,
space		= $(empty) $(empty)

FAIL_COLOR	= $(shell tput setaf 1)
OK_COLOR	= $(shell tput setaf 2)
INFO_COLOR	= $(shell tput setaf 4)
RST_COLOR	= $(shell tput sgr0)
NBR_COLUMNS	= $(shell tput cols)

# Prints the message in $1, runs the command in $2 then prints DONE or FAILED
run_command = \
	msg="$(1)"; \
	padlen=$$(( $(NBR_COLUMNS) - $${\#msg} )); \
	echo -n "$$msg"; \
	output=$$({ $(2) } 2>&1; exit $$?;); \
	RETVAL=$$?; \
	if [ $$RETVAL -eq 0 ]; then \
		printf '%s%*s%s\n' "$(OK_COLOR)" $$padlen "[DONE]" "$(RST_COLOR)"; \
	else \
		printf '%s%*s%s\n' "$(FAIL_COLOR)" $$padlen "[FAILED]" "$(RST_COLOR)"; \
		echo " $(INFO_COLOR)[ERROR]$(RST_COLOR)  " "$$output" >&2; \
		echo " $(INFO_COLOR)[COMMAND]$(RST_COLOR)" '$(subst ','"'"',$(2))' >&2; \
		exit $$RETVAL; \
	fi;

# Creates the directory $1 (and prints a message)
create_dir = \
	@$(call run_command,Creating directory $(1),mkdir -p $(1); touch $(1);)

## Common rules

.SUFFIXES: .c .o
%.o: %.c
	@$(call run_command,  Compiling $<,$(CC) $(CFLAGS) -o $@ -c $<;)

clean:
	@$(call run_command,Deleting object files,find $(SRCDIR) -name "*.o" -exec rm {} \;;)
	@$(call run_command,Deleting executables,find $(BINDIR) -type f -exec rm {} \;;)

$(BINDIR):
	@$(call create_dir,$@)

## Installation rules

install:
uninstall:

ifdef PREFIX
$(PREFIX):
	@$(call create_dir,$@)

ifndef INSTALL_BINDIR
INSTALL_BINDIR	= $(PREFIX)/bin
endif
endif

ifdef INSTALL_BINDIR

install: install_exec
uninstall: uninstall_exec

$(INSTALL_BINDIR):
	@$(call create_dir,$@)

ifndef INSTALL_BINARIES
INSTALL_BINARIES = $(shell $(MAKE) -f makefile.d -pn | grep '^exec:' | cut -d: -f2 | sed -r 's/ *(.*) */\1/g')
endif

install_exec: $(INSTALL_BINARIES) |$(INSTALL_BINDIR)
	@$(call run_command,Installing binaries into $(INSTALL_BINDIR),cp $(BINDIR)/{$(subst $(space),$(comma),$(INSTALL_BINARIES))} $(INSTALL_BINDIR);)
uninstall_exec: makefile.d
	@$(call run_command,Uninstalling binaries from $(INSTALL_BINDIR),rm -f $(INSTALL_BINDIR)/{$(subst $(space),$(comma),$(INSTALL_BINARIES))};)

endif # INSTALL_BINDIR

## Distributables

dist: tar bz2
tar: makefile.d clean
	@$(call run_command,  Creating ../$(PROJECT)_$(PROJECT_VERSION).tar.gz,tar -zco -C .. $(EXCLUDES) -f "../$(PROJECT)_$(PROJECT_VERSION).tar.gz" "$(shell basename $(CURDIR))";)

bz2: makefile.d clean
	@$(call run_command,  Creating ../$(PROJECT)_$(PROJECT_VERSION).tar.bz2,tar -jco -C .. $(EXCLUDES) -f "../$(PROJECT)_$(PROJECT_VERSION).tar.bz2" "$(shell basename $(CURDIR))";)

distclean: clean
	@$(call run_command,Deleting dependencies file,rm -f makefile.d;)
	@$(call run_command,Deleting dist files,rm -f ../$(PROJECT)_$(PROJECT_VERSION).tar.gz && rm -f ../$(PROJECT)_$(PROJECT_VERSION).tar.bz2;)

## Dependencies

deps:
	@$(call run_command,Building dependencies,eval $(build_dependencies_file))

makefile.d:
	@$(call run_command,Building dependencies,eval $(build_dependencies_file))

build_dependencies_file = \
	TEMP_FILE=`mktemp /tmp/makefile.d.XXXXXX`; \
	C_FILES=`find $(SRCDIR) -type f -name "*.c"`; \
	for file in $$C_FILES; do \
		$(CC) $(CFLAGS) -MM -MT $${file/%.c/.o} $$file | tr -d "\\n\\\\" >> $$TEMP_FILE; \
		[ $${PIPESTATUS[0]} -ne 0 ] && rm -f $$TEMP_FILE && exit -1; \
		echo -e "\n" >> $$TEMP_FILE; \
	done; \
	main_files=`grep -Hs " main(" $$C_FILES | cut -f1 -d':'`; \
	for file in $$main_files; do \
		execname=`basename $$file .c`; \
		objs="$${file/%.c/.o}"; \
		headers=`$(CC) $(CFLAGS) -MM $$file | tr " " "\\n" | grep ".h$$" | sort -u | tr "\\n" " "; exit $${PIPESTATUS[0]};`; \
		[ $$? -ne 0 ] && rm -f $$TEMP_FILE && exit -1; \
		for header in $$headers; do \
			if [ -f $${header/%.h/.c} ]; then \
				objs+=" $${header/%.h/.o}"; \
			fi; \
			for sub_h in `grep "^$${header/%.h/.o}:" $$TEMP_FILE | tr " " "\\n" | grep ".h$$" | tr "\\n" " "`; do \
				if [ -f $${sub_h/%.h/.c} ]; then \
					objs+=" $${sub_h/%.h/.o}"; \
				fi; \
			done; \
		done; \
		objs=`echo -n "$$objs"  | tr " " "\\n" | sort -u | tr "\\n" " "`; \
		echo "exec: $$execname" >> $$TEMP_FILE; \
		echo "$$execname: \$$(BINDIR)/$$execname" >> $$TEMP_FILE; \
		echo "\$$(BINDIR)/$$execname: $$objs |\$$(BINDIR)" >> $$TEMP_FILE; \
		echo "	@\$$(call run_command, Linking \$$@,\$$(CC) \$$(LDFLAGS) -o \$$@ $$^;)" >> $$TEMP_FILE; \
		echo >> $$TEMP_FILE; \
	done; \
	cp $$TEMP_FILE makefile.d; \
	rm $$TEMP_FILE; \
	exit 0;
