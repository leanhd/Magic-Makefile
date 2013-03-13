Magic-Makefile
==============

A makefile that generates the dependences of simple C projets automatically.
This means that you won't need to manually specify which object files have to be
linked together in order to generate the executable.

Just write your C code and type `make` in a terminal when you are done. Your
project will be compiled and binaries will be generated in the `bin` dir (by
default). You just have to make sure that your functions are declared in the
header file corresponding to your `.c` files.

If your project fails to build, try rebuilding the dependencies by running
`make deps`. You will need to do this every time you modify the dependencies
among your files.

If you which to change the default behaviour of the makefile (like the DEBUG
macro, defiled as 0 by default) or add your own rules, please do so in
`makefile.inc`.

You should not use special characters or blanc characters (space, tab, new line)
in your file names.

This makefile also supports basic installation of your binary files. All you
need to do is define PREFIX in makefile.inc then run `make install` to install
your project.
