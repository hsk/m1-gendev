#
# HINT: If makeinfo is missing on Ubuntu, install texinfo package.
#

SUDO?= sudo
MGET?= wget
MAKE?= make

ORIG_USER:=$(shell whoami)

BUILDDIR?=$(CURDIR)/build
GENDEV?=/opt/gendev/
TOPDIR=$(CURDIR)

VER?=dev

PATH := $(BUILDDIR)/bin:$(PATH)

build: toolchain_build tools_build sgdk_build
	echo "Done"

$(BUILDDIR):
	mkdir -p $@

toolchain_build: $(BUILDDIR)
	cp -rf /opt/homebrew/Cellar/gendev-gcc/10.2.1/* build/.

toolchain_clean:
	rm -rf build/*

tools_build:
	cd tools && $(MAKE) tools_build

tools_clean:
	cd tools && $(MAKE) tools_clean

sgdk_samples:
	cd sgdk && $(MAKE) sample_clean samples

$(GENDEV):
	if [ -w /opt ]; then \
		mkdir -p $(GENDEV); \
	else \
		$(SUDO) mkdir -p $@; \
		$(SUDO) chown $(ORIG_USER):$(ORIG_USER) $@; \
	fi

install: $(GENDEV)
	echo "export GENDEV=$(GENDEV)" > ~/.gendev
	echo "export PATH=\$$GENDEV/bin:\$$PATH" >> ~/.gendev
	#$(SUDO) chmod 777 $@
	cp -r $(BUILDDIR)/* $(GENDEV)/.

release: deb txz
	echo "Release"

dist:
	mkdir -p dist

txz: dist/gendev_$(VER).txz
dist/gendev_$(VER).txz: dist pkg_build
	tar -C pkg_build  -cJf dist/gendev_$(VER).txz opt

pkg_build:
	mkdir -p pkg_build/opt/gendev
	cp -r $(BUILDDIR)/* pkg_build/opt/gendev/.
	cp -r pkg/* pkg_build/.

deb: dist dist/gendev_$(VER)_all.deb
dist/gendev_$(VER)_all.deb: pkg_build
	sed -i 's/##VER##/$(VER)/g' pkg_build/DEBIAN/control
	cd dist && dpkg-deb -Zxz -z9 --build $(TOPDIR)/pkg_build .

sgdk_build:
	cd sgdk && GENDEV=$(BUILDDIR) $(MAKE) install

sgdk_clean:
	- cd sgdk && $(MAKE) clean

clean: tools_clean toolchain_clean sgdk_clean
	-rm -rf $(BUILDDIR)
	-rm -rf pkg_build
	-rm -rf dist

#########################################################
#########################################################
#########################################################

#########################################################
#########################################################
#########################################################