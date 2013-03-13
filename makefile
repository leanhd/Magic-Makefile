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

comma		= ,
empty		=
space		= $(empty) $(empty)

FAIL_COLOR	= $(shell tput setaf 1)
OK_COLOR	= $(shell tput setaf 2)
INFO_COLOR	= $(shell tput setaf 4)
RST_COLOR	= $(shell tput sgr0)
NBR_COLUMNS	= $(shell tput cols)

# Prints the message in $1, runs the command in $2 then prints DONE or FAIL
run_command = \
	msg="$(1)"; \
	padlen=$$(( $(NBR_COLUMNS) - $${\#msg} )); \
	echo -n "$$msg"; \
	if err=`$(2) 2>&1`; then \
		printf '%s%*s%s\n' "$(OK_COLOR)" $$padlen "[DONE]" "$(RST_COLOR)"; \
	else \
		errcode=$$?; \
		printf '%s%*s%s\n' "$(FAIL_COLOR)" $$padlen "[FAIL]" "$(RST_COLOR)"; \
		echo " $(INFO_COLOR)[COMMAND]$(RST_COLOR)" "$(2)"; \
		echo " $(INFO_COLOR)[ERROR]$(RST_COLOR)  " "$$err" >&2; \
		exit $$errcode; \
	fi;

# Creates the directory $1
create_dir = \
	@$(call run_command,Creating directory $(1),mkdir -p $(1); touch $(1);)

## Common rules

.SUFFIXES: .c .o
%.o: %.c
	@$(call run_command,  Compiling $<,$(CC) $(CFLAGS) -o $@ -c $<)

clean:
	@$(call run_command,Deleting object files,find $(SRCDIR) -name "*.o" -exec rm {} \;)
	@$(call run_command,Deleting executables,find $(BINDIR) -type f -exec rm {} \;)

$(BINDIR):
	@$(call create_dir,$@)

## Dependencies file creation

deps:
	@$(call create_dependencies_file)

makefile.d:
	@$(call create_dependencies_file)

create_dependencies_file = \
	echo "Building dependencies"; \
	TEMP_FILE=`mktemp /tmp/makefile.d.XXXXXX`; \
	C_FILES=`find $(SRCDIR) -type f -name "*.c"`; \
	for file in $$C_FILES; do \
		$(CC) $(CFLAGS) -MM -MT $${file/%.c/.o} $$file | tr -d "\\n\\\\" >> $$TEMP_FILE; \
		echo -e "\n" >> $$TEMP_FILE; \
	done; \
	for file in `grep -Hs " main(" $$C_FILES | cut -f1 -d':'`; do \
		execname=`basename $$file .c`; \
		objs="$${file/%.c/.o}"; \
		for header in `$(CC) $(CFLAGS) -MM $$file | tr " " "\\n" | grep ".h$$" | sort -u | tr "\\n" " "`; do \
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
		echo "	@\$$(call run_command, Linking \$$@,\$$(CC) \$$(LDFLAGS) -o \$$@ $$^)" >> $$TEMP_FILE; \
		echo >> $$TEMP_FILE; \
	done; \
	cp $$TEMP_FILE makefile.d; \
	rm $$TEMP_FILE;

## Distributables files creation

dist: tar bz2
tar: makefile.d clean
	@$(call run_command,  Creating ../$(PROJECT)_$(PROJECT_VERSION).tar.gz,tar -zco -C .. $(EXCLUDES) -f "../$(PROJECT)_$(PROJECT_VERSION).tar.gz" "$(shell basename $(CURDIR))")

bz2: makefile.d clean
	@$(call run_command,  Creating ../$(PROJECT)_$(PROJECT_VERSION).tar.bz2,tar -jco -C .. $(EXCLUDES) -f "../$(PROJECT)_$(PROJECT_VERSION).tar.bz2" "$(shell basename $(CURDIR))")

distclean: clean
	@$(call run_command,Deleting dependencies file,rm -f makefile.d)
	@$(call run_command,Deleting dist files,rm -f ../$(PROJECT)_$(PROJECT_VERSION).tar.gz && rm -f ../$(PROJECT)_$(PROJECT_VERSION).tar.bz2)

## Installation rules

ifdef DESTDIR

install: install_exec
uninstall: uninstall_exec

$(DESTDIR):
	@$(call create_dir,$@)

ifdef INSTBIN
install_exec: $(INSTBIN) |$(DESTDIR)
	@$(call run_command,Installing binaries into $(DESTDIR),cp $(BINDIR)/{$(subst $(space),$(comma),$(INSTBIN))} $(DESTDIR))
#	@echo "Installing binaries into $(DESTDIR)"
#	@for f in $(INSTBIN); do \
#		if [ -f $(BINDIR)/$$f ]; then \
#			echo "  Installing $$f"; \
#			cp $(BINDIR)/$$f $(DESTDIR); \
#		fi; \
#	done;

uninstall_exec: makefile.d
	@echo "Uninstalling binaries from $(DESTDIR)"
	@for f in $(INSTBIN); do \
		if [ -f $(DESTDIR)/$$f ]; then \
			echo "  Removing $$f"; \
			rm $(DESTDIR)/$$f; \
		fi; \
	done;
else
install_exec: exec |$(DESTDIR)
	@$(call run_command,Installing binaries into $(DESTDIR),cp $(BINDIR)/* $(DESTDIR))

uninstall_exec: makefile.d
	@echo "Uninstalling binaries from $(DESTDIR)"
	@for f in `$(MAKE) -f makefile.d -pn | grep '^exec:' | cut -d: -f2`; do \
		if [ -f $(DESTDIR)/$$f ]; then \
			echo "  Removing $$f"; \
			rm $(DESTDIR)/$$f; \
		fi; \
	done;
endif # INSTBIN

endif # DESTDIR