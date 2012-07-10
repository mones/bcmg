#
# Makefile for CVS Claws Mail and plugins under Debian GNU/Linux
#
# Copyright 2011-2012 by Ricardo Mones <ricardo@mones.org>
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
CLAWS_FLAGS=
# plugins to be built
PLUGIN_LIST=acpi_notifier address_keeper archive attachwarner att_remover bsfilter clamd fancy fetchinfo gdata geolocation gtkhtml2_viewer mailmbox newmail notification perl python rssyl spam_report tnef_parse vcalendar
# patching
CLAWS_SER=./claws.series
PLUGINS_SER=./plugins.series

all: build-claws build-plugins

build-claws: update-claws copy-claws patch-claws install-claws

build-plugins: update-plugins copy-plugins patch-plugins install-plugins

all-in-mem:
	rm -rf $ $(RAMD)/b-claws $(RAMD)/b-plugins
	cp ./Makefile $(RAMD)
	make -C $(RAMD)

copy-from-mem:
	cp -rp $(RAMD)/claws .
	cp -rp $(RAMD)/plugins .
	cp -rp $(RAMD)/b-claws .
	cp -rp $(RAMD)/b-plugins .

all-in-mem-copy: all-in-mem copy-from-mem

save-patch-claws:
	cd claws && ( cvs diff -u 2> /dev/null > ../$@ || true ) && cd ..

save-patch-$(PLUGIN):
	cd plugins/$(PLUGIN) && ( cvs diff -u 2> /dev/null > ../../$@ || true ) && cd ../..

save-patches: save-patch-claws
	for plugin in $(PLUGIN_LIST); do $(MAKE) PLUGIN=$$plugin save-patch-$$plugin || break; done
	for patch in save-patch-*; do test -s $$patch || rm -f $$patch; done

clean-patches:
	rm -f save-patch-*

start-from-scratch:
	rm -f $(CLAWS_SER) $(PLUGINS_SER)
	rm -rf ./claws ./b-claws ./plugins ./b-plugins
	rm -rf $(PREFIX)/*

#######################################################################
# core
#######################################################################

claws:
	cvs -z3 -d:pserver:anonymous@claws-mail.org:/ checkout -r gtk2 claws

update-claws: claws
	cd claws && cvs -z3 update -dP && cd ..

copy-claws:
	rm -rf b-claws
	cp -rp claws b-claws

patch-claws:
	test ! -f $(CLAWS_SER) || for patch in `cat $(CLAWS_SER)`; do echo "Applying claws patch $$patch" && cd b-claws && patch -p0 < ../$$patch && cd ..; done

compile-claws:
	@echo "compile-claws: "`date`
	cd b-claws && env PKG_CONFIG_PATH=$(PKG_CP) ./autogen.sh && env PKG_CONFIG_PATH=$(PKG_CP) ./configure $(CLAWS_FLAGS) --prefix=$(PREFIX) && make -j$(CPUS) && cd ..
	@echo "compile-claws: "`date`

install-claws: compile-claws
	cd b-claws && make install && cd ..

dist-claws:
	cd b-claws && ./autogen.sh && make -j$(CPUS) dist && cd ..

#######################################################################
# plugins
#######################################################################

plugins:
	cvs -z3 -d:pserver:anonymous@claws-mail.org:/ checkout -r gtk2 plugins

update-plugins: plugins
	cd plugins && cvs -z3 update -dP && cd ..

copy-plugins:
	rm -rf b-plugins
	cp -rp plugins b-plugins

patch-plugins:
	test ! -f $(PLUGINS_SER) || for patch in `cat $(PLUGINS_SER)`; do echo "Applying plugins patch $$patch" && cd b-plugins && patch -p0 < ../$$patch && cd ..; done

b-plugins/auto-$(PLUGIN):
	cd b-plugins/$(PLUGIN) && env PKG_CONFIG_PATH=$(PKG_CP) ./autogen.sh && cd ../.. && touch $@

b-plugins/config-$(PLUGIN): b-plugins/auto-$(PLUGIN)
	cd b-plugins/$(PLUGIN) && env PKG_CONFIG_PATH=$(PKG_CP) ./configure --prefix=$(PREFIX) && cd ../.. && touch $@

b-plugins/build-$(PLUGIN): b-plugins/config-$(PLUGIN)
	cd b-plugins/$(PLUGIN) && make -j$(CPUS) && cd ../.. && touch $@

b-plugins/install-$(PLUGIN): b-plugins/build-$(PLUGIN)
	cd b-plugins/$(PLUGIN) && make install && cd ../.. && touch $@
	touch $@

clean-plugins:
	rm -f b-plugins/install-* b-plugins/build-* b-plugins/config-* b-plugins/auto-*

compile-plugins:
	@echo "compile-plugins: "`date`
	for plugin in $(PLUGIN_LIST); do $(MAKE) PLUGIN=$$plugin b-plugins/build-$$plugin || break; done
	@echo "compile-plugins: "`date`

install-plugins: compile-plugins
	for plugin in $(PLUGIN_LIST); do $(MAKE) PLUGIN=$$plugin b-plugins/install-$$plugin || break; done

query-plugins:
	@for plugin in $(PLUGIN_LIST); do cd b-plugins/$$plugin && echo "$$plugin "`grep '_VERSION=' ./configure.ac | head -4 | cut -f2 -d= | xargs | sed 's, ,.,g'` && cd ../..; done

.PHONY: build-claws build-plugins update-claws copy-claws patch-claws compile-claws install-claws update-plugins copy-plugins patch-plugins clean-plugins compile-plugins install-plugins all-in-mem copy-from-mem all-in-mem-copy save-patches clean-patches start-from-scratch

