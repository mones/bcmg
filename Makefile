#
# Makefile for Git Claws Mail and plugins under Debian GNU/Linux
#
# Copyright 2011-2013 by Ricardo Mones <ricardo@mones.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

CPUS:=$(shell grep processor /proc/cpuinfo | wc -l)
PREFIX=/opt/claws
RAMD=/dev/shm
PKG_CP=$(PREFIX)/lib/pkgconfig
# additional flags for core configuration
CLAWS_FLAGS=--enable-maintainer-mode
# patching
CLAWS_SER=./claws.series

all: build-claws

build-claws: update-claws copy-claws patch-claws install-claws

all-in-ram:
	rm -rf $ $(RAMD)/b-claws
	cp ./Makefile $(RAMD)
	make -C $(RAMD)

copy-from-ram:
	cp -rp $(RAMD)/claws .
	cp -rp $(RAMD)/b-claws .

all-in-ram-copy: all-in-ram copy-from-ram

save-patch-claws:
	cd claws && ( cvs diff -u 2> /dev/null > ../$@ || true ) && cd ..

start-from-scratch:
	rm -f $(CLAWS_SER)
	rm -rf ./claws ./b-claws
	rm -rf $(PREFIX)/*

#######################################################################
# core
#######################################################################

claws:
	git clone git://git.claws-mail.org/claws.git

update-claws: claws
	cd claws && git pull --all && cd ..

copy-claws:
	rm -rf b-claws
	cp -rp claws b-claws

patch-claws:
	test ! -f $(CLAWS_SER) || for patch in `cat $(CLAWS_SER)`; do echo "Applying claws patch $$patch" && cd b-claws && patch -p0 < ../$$patch && cd ..; done

b-claws/configure:
	@echo "autogen-claws: "`date`
	cd b-claws && env PKG_CONFIG_PATH=$(PKG_CP) ./autogen.sh && cd ..
	@echo "autogen-claws: "`date`

b-claws/Makefile: b-claws/configure
	@echo "configure-claws: "`date`
	cd b-claws && env PKG_CONFIG_PATH=$(PKG_CP) ./configure $(CLAWS_FLAGS) --prefix=$(PREFIX) && cd ..
	@echo "configure-claws: "`date`

compile-claws: b-claws/Makefile
	@echo "compile-claws: "`date`
	cd b-claws && make -j$(CPUS) && cd ..
	@echo "compile-claws: "`date`

install-claws: compile-claws
	cd b-claws && make install && cd ..

dist-claws:
	cd b-claws && ./autogen.sh && make -j$(CPUS) dist && cd ..

.PHONY: build-claws update-claws copy-claws patch-claws configure-claws compile-claws install-claws all-in-ram copy-from-ram all-in-ram-copy save-patches clean-patches start-from-scratch

