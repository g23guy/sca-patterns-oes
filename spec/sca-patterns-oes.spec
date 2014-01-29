# Copyright (C) 2013 SUSE LLC
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

# norootforbuild
# neededforbuild

%define sca_common sca
%define patdirbase /usr/lib/%{sca_common}
%define patdir %{patdirbase}/patterns
%define patuser root
%define patgrp root
%define mode 544
%define category OES

Name:         sca-patterns-oes
Summary:      Supportconfig Analysis Patterns for OES
URL:          https://bitbucket.org/g23guy/sca-patterns-oes
Group:        Documentation/SuSE
License:      GPL-2.0
Autoreqprov:  on
Version:      1.3
Release:      3
Source:       %{name}-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}
Buildarch:    noarch
Requires:     sca-patterns-base

%description
Supportconfig Analysis (SCA) appliance patterns to identify known
issues relating to all versions of Open Enterprise Server (OES)

Authors:
--------
    Jason Record <jrecord@suse.com>

%prep
%setup -q

%build

%install
pwd;ls -la
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/all
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/oes11all
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/oes1all
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/oes2all
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/oes2sp3
install -m %{mode} patterns/%{category}/all/* $RPM_BUILD_ROOT/%{patdir}/%{category}/all
install -m %{mode} patterns/%{category}/oes11all/* $RPM_BUILD_ROOT/%{patdir}/%{category}/oes11all
install -m %{mode} patterns/%{category}/oes1all/* $RPM_BUILD_ROOT/%{patdir}/%{category}/oes1all
install -m %{mode} patterns/%{category}/oes2all/* $RPM_BUILD_ROOT/%{patdir}/%{category}/oes2all
install -m %{mode} patterns/%{category}/oes2sp3/* $RPM_BUILD_ROOT/%{patdir}/%{category}/oes2sp3

%files
%defattr(-,%{patuser},%{patgrp})
%dir %{patdirbase}
%dir %{patdir}
%dir %{patdir}/%{category}
%dir %{patdir}/%{category}/all
%dir %{patdir}/%{category}/oes11all
%dir %{patdir}/%{category}/oes1all
%dir %{patdir}/%{category}/oes2all
%dir %{patdir}/%{category}/oes2sp3
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/all/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/oes11all/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/oes1all/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/oes2all/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/oes2sp3/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Jan 29 2014 jrecord@suse.com
- includes pertinent patterns from sca-patterns-samba
- includes pertinent patterns from sca-patterns-basic
- includes pertinent patterns from sca-patterns-ncs

* Thu Jan 16 2014 jrecord@suse.com
- relocated files according to FHS
- added and fixed links in casadns-00001.pl

* Wed Dec 20 2013 jrecord@suse.com
- separated as individual RPM package

