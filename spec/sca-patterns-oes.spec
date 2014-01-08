# Copyright (C) 2013 SUSE LLC
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

# norootforbuild
# neededforbuild

%define produser sca
%define prodgrp sdp
%define patuser root
%define patgrp root
%define patdir /var/opt/%{produser}/patterns
%define mode 544
%define category OES

Name:         sca-patterns-oes
Summary:      Supportconfig Analysis Patterns for OES
URL:          https://bitbucket.org/g23guy/sca-patterns-oes
Group:        Documentation/SuSE
Distribution: SUSE Linux Enterprise
Vendor:       SUSE Support
License:      GPL-2.0
Autoreqprov:  on
Version:      1.2
Release:      1
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
%dir /var/opt/%{produser}
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
* Wed Dec 20 2013 jrecord@suse.com
- separated as individual RPM package

