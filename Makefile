#
# Makefile for Git Claws Mail and plugins under Debian GNU/Linux
#
# Copyright 2011-2016 by Ricardo Mones <ricardo@mones.org>
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

CPUS   ?= $(shell grep processor /proc/cpuinfo | wc -l)
URL    ?= http://git.claws-mail.org/readonly/claws.git
BRANCH ?= master
PREFIX ?= /opt/claws
RAMD   ?= /dev/shm
LOGDIR ?= $(shell pwd)
PKG_CP := $(PREFIX)/lib/pkgconfig
# additional flags for core configuration
CLAWS_FLAGS ?= --enable-maintainer-mode
# local patching
CLAWS_GAM_DIR := claws.series
CLAWS_GAM_DIR_P := $(wildcard $(CLAWS_GAM_DIR)/*.patch)
CLAWS_GAM := ./claws.series.git
# utilities
AHEAD := $(shell test -d b-claws && cd b-claws && git rev-list --count origin..$(BRANCH) || echo 0 )
MODIF := $(shell test -d b-claws && cd b-claws && git ls-files -m | grep -v po/.*.po | wc -l || echo 0)
BRNCH := $(shell test -d b-claws && cd b-claws && git branch | grep ^\* | cut -f2 -d\ )

all: build-claws

build-claws: update-claws copy-claws patch-claws unconfigure-claws install-claws

build-claws-as-is: copy-claws patch-claws install-claws

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
	rm -rf ./claws ./b-claws
	rm -rf $(PREFIX)/*

build-info:
	@echo "Remote: "$(URL)
	@echo "Branch: "$(BRANCH)
	@echo "Prefix: "$(PREFIX)
	@echo "Logs  : "$(LOGDIR)
	@echo "Cores : "$(CPUS)
	@# echo "RAMdev: "$(RAMD)

#######################################################################
# core
#######################################################################

claws:
	git clone $(URL)

update-claws: claws
	cd claws && git pull --all && cd ..

copy-claws:
	test ! -d b-claws && git clone claws b-claws || true
	test "$(BRNCH)" != $(BRANCH) && cd b-claws && git checkout $(BRANCH) && cd .. || true
	test $(MODIF) -eq 0 && cd b-claws && git checkout `git ls-files -m | xargs` && cd .. || true
	test $(AHEAD) -gt 0 && cd b-claws && git reset --hard @~$(AHEAD) && cd .. || true
	cd b-claws && git pull --all && cd ..

patch-claws-file:
	@test ! -f $(CLAWS_GAM) || for patch in `cat $(CLAWS_GAM)`; do echo "***** $$patch" && cd b-claws && git am ../$$patch && cd ..; done

patch-claws-dir:
	@test ! -d $(CLAWS_GAM_DIR) || for patch in $(CLAWS_GAM_DIR_P); do echo "***** $$patch" && cd b-claws && git am ../$$patch && cd ..; done

patch-claws:
	@test -d $(CLAWS_GAM_DIR) && $(MAKE) patch-claws-dir || true
	@test ! -d $(CLAWS_GAM_DIR) -a -f $(CLAWS_GAM) && $(MAKE) patch-claws-file || true

b-claws/configure:
	@echo "autogen-claws: "`date`
	cd b-claws && env PKG_CONFIG_PATH=$(PKG_CP) ./autogen.sh > $(LOGDIR)/log-autogen-claws.txt 2>&1 && cd ..
	@echo "autogen-claws: "`date`

b-claws/Makefile: b-claws/configure
	@echo "configure-claws: "`date`
	cd b-claws && env PKG_CONFIG_PATH=$(PKG_CP) ./configure $(CLAWS_FLAGS) --prefix=$(PREFIX) > $(LOGDIR)/log-configure-claws.txt 2>&1 && cd ..
	@echo "configure-claws: "`date`

compile-claws: b-claws/Makefile
	@echo "compile-claws: "`date`
	cd b-claws && make -j$(CPUS) > $(LOGDIR)/log-compile-claws.txt 2>&1 && cd ..
	@echo "compile-claws: "`date`

unconfigure-claws:
	rm -f b-claws/Makefile b-claws/configure

rebuild-claws: unconfigure-claws compile-claws

install-claws: compile-claws
	@echo "install-claws: "`date`
	cd b-claws && make install > $(LOGDIR)/log-install-claws.txt 2>&1 && cd ..
	@echo "install-claws: "`date`

reinstall-claws: rebuild-claws install-claws

redo-claws:
	rm -rf b-claws
	$(MAKE) build-claws

dist-claws:
	cd b-claws && ./autogen.sh && make -j$(CPUS) dist && cd ..

log:
	cd claws && git log || cd ..

b-log:
	cd b-claws && git log || cd ..

bootstrap-debian:
	sudo apt-get build-dep claws-mail

.PHONY: build-claws update-claws copy-claws patch-claws patch-claws-file patch-claws-dir configure-claws compile-claws rebuild-claws install-claws all-in-ram copy-from-ram all-in-ram-copy save-patches clean-patches start-from-scratch log b-log build-info
