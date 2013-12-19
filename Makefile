OBSPACKAGE=sca-patterns-oes
SVNDIRS=patterns
PKGSPEC=$(OBSPACKAGE).spec
PATBASE='/var/opt/sca/patterns'
VERSION=$(shell awk '/Version:/ { print $$2 }' spec/${PKGSPEC})
RELEASE=$(shell awk '/Release:/ { print $$2 }' spec/${PKGSPEC})
SRCDIR=$(OBSPACKAGE)-$(VERSION)
SRCFILE=$(SRCDIR).tar.gz
BUILDDIR=/usr/src/packages

default: rpm

build:
	@echo build: Building package files
#	gzip -9f man/*
	
install:
	@echo install: Creating directory structure
	@install -d \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES/all \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES/oes11all \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES/oes1all \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES/oes2all \
		$(RPM_BUILD_ROOT)/$(PATBASE)/OES/oes2sp3 \
	@echo install: Installing files
	@for i in all oes11all oes1all oes2all oes2sp3; do install -m 555 patterns/OES/$$i/* $(RPM_BUILD_ROOT)/$(PATBASE)/OES/$$i  ; done

uninstall:
	@echo uninstall: Uninstalling from build directory
	@rm -rf $(RPM_BUILD_ROOT)
	@rm -rf $(BUILDDIR)/SOURCES/$(SRCFILE).gz
	@rm -rf $(BUILDDIR)/SPECS/$(PKGSPEC)
	@rm -rf $(BUILDDIR)/BUILD/$(SRCDIR)
	@rm -f $(BUILDDIR)/SRPMS/$(OBSPACKAGE)*.src.rpm
	@rm -f $(BUILDDIR)/RPMS/noarch/$(OBSPACKAGE)*.rpm

dist:
	@echo dist: Creating distribution source tarball
	@mkdir -p $(SRCDIR)
	@for i in $(SVNDIRS); do cp -a $$i $(SRCDIR); done
	@cp COPYING.GPLv2 $(SRCDIR)
	@cp Makefile $(SRCDIR)
	@tar zcf $(SRCFILE) $(SRCDIR)/*
	@rm -rf $(SRCDIR)
	@mv -f $(SRCFILE) src

clean: uninstall
	@echo clean: Cleaning up make files
	@rm -rf $(OBSPACKAGE)*
	@for i in $(SVNDIRS); do rm -f $$i/*~; done
	@rm -f src/$(OBSPACKAGE)-*gz
	@rm -f *~

prep: dist
	@echo prep: Copying source files for build
	@cp src/$(SRCFILE) $(BUILDDIR)/SOURCES
	@cp spec/$(PKGSPEC) $(BUILDDIR)/SPECS

rpm: clean prep
	@echo rpm: Building RPM packages
	@rpmbuild -ba $(BUILDDIR)/SPECS/$(PKGSPEC)
	mv $(BUILDDIR)/SRPMS/$(OBSPACKAGE)-* .
	mv $(BUILDDIR)/RPMS/noarch/$(OBSPACKAGE)-* .
	@rm -rf $(BUILDDIR)/BUILD/$(SRCDIR)
	@rm -f $(BUILDDIR)/SOURCES/$(SRCFILE)
	@rm -f $(BUILDDIR)/SPECS/$(PKGSPEC)
	@ls -ls $$LS_OPTIONS

commit: rpm
	@echo commit: Committing changes to GIT
	@git commit -a -m "Committing Source: $(OBSPACKAGE)-$(VERSION)-$(RELEASE)"
	@echo

push: commit
	@echo push: Pushing changes to GIT
	@git push -u origin master
	@echo

help:
	@clear
	@make -v
	@echo
	@echo Make options for package: $(OBSPACKAGE)
	@echo make {build, install, uninstall, dist, clean, prep, rpm[default]}
	@echo
