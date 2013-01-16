Magic-Makefile
==============

A makefile that generates the dependences of simple C projets automatically.
This means that you won't need to manually specify which object files have to be
linked together in order to generate the executable.

Just write your C code and type `make` in a terminal  when you are done. Your
project will be compiled and binaries will be generated in the `bin` dir (by
default).

If you which to change the default behaviour of the makefile (like the DEBUG
macro, defiled as 0 by default) or add your own rules, please do so in
`makefile.inc`.
