#
# =BEGIN MIT LICENSE
# 
# The MIT License (MIT)
#
# Copyright (c) 2014 The CrossBridge Team
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# =END MIT LICENSE
#

.PHONY: debug clean all 

# Detect host 
$?UNAME=$(shell uname -s)
#$(info $(UNAME))
ifneq (,$(findstring CYGWIN,$(UNAME)))
	$?nativepath=$(shell cygpath -at mixed $(1))
	$?unixpath=$(shell cygpath -at unix $(1))
else
	$?nativepath=$(abspath $(1))
	$?unixpath=$(abspath $(1))
endif

# CrossBridge SDK Home
ifneq "$(wildcard $(call unixpath,$(FLASCC_ROOT)/sdk))" ""
 $?FLASCC:=$(call unixpath,$(FLASCC_ROOT)/sdk)
else
 $?FLASCC:=/path/to/crossbridge-sdk/
endif
$?ASC2=java -jar $(call nativepath,$(FLASCC)/usr/lib/asc2.jar) -merge -md -parallel
 
# Auto Detect AIR/Flex SDKs
ifneq "$(wildcard $(AIR_HOME)/lib/compiler.jar)" ""
 $?FLEX=$(AIR_HOME)
else
 $?FLEX:=/path/to/adobe-air-sdk/
endif

# C/CPP Compiler
$?BASE_CFLAGS=-Werror -Wno-write-strings -Wno-trigraphs
$?EXTRACFLAGS=
$?OPT_CFLAGS=-O4

# ASC2 Compiler
$?MXMLC_DEBUG=true
$?SWF_VERSION=26
$?SWF_SIZE=800x600

all: check
	@echo "------- Example: Box2D --------"

	mkdir -p build
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):$(PATH)" CC=gcc CXX=g++ CFLAGS="$(OPT_CFLAGS) $(BASE_CFLAGS) $(EXTRACFLAGS)" CXXFLAGS="$(OPT_CFLAGS) $(BASE_CFLAGS) $(EXTRACFLAGS)" cmake ../Box2D/

	make recompile

recompile:
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):$(PATH)" make -j8

	cp -f as3api.h build/
	cd build && "$(FLASCC)/usr/bin/swig" -as3 -c++ -I../Box2D/ -DSWIGPP -module Box2D -outdir . -includeall -ignoremissing as3api.h
	cd build && $(ASC2) -import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) -import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) Box2D.as
	cd build && "$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) $(OPT_CFLAGS) -I../Box2D/ Box2D.abc as3api_wrap.cxx Box2D/libBox2D.a -emit-swc=crossbridge.Box2D -o ../release/crossbridge-box2d.swc $(EXTRACFLAGS)

	make swfs

swfs:
	"$(FLEX)/bin/mxmlc" -source-path+=src/main/actionscript -library-path+=release/crossbridge-box2d.swc -debug=$(MXMLC_DEBUG) src/main/actionscript/HelloWorld.as -o bin/HelloWorld.swf
	"$(FLEX)/bin/mxmlc" -source-path+=src/main/actionscript -library-path+=release/crossbridge-box2d.swc -debug=$(MXMLC_DEBUG) src/main/actionscript/Boxes.as -o bin/Boxes.swf

debug:
	make all OPT_CFLAGS="-O0 -g" MXMLC_DEBUG=true

# Self check
check:
	@if [ -d $(FLASCC)/usr/bin ] ; then true ; \
	else echo "Couldn't locate CrossBridge SDK directory, please invoke make with \"make FLASCC=/path/to/CrossBridge/ ...\"" ; exit 1 ; \
	fi
	@if [ -d "$(FLEX)/bin" ] ; then true ; \
	else echo "Couldn't locate Adobe AIR or Apache Flex SDK directory, please invoke make with \"make FLEX=/path/to/AirOrFlex  ...\"" ; exit 1 ; \
	fi
	@echo "ASC2: $(ASC2)"

clean:
	rm -rf build *.swf *.swc 
