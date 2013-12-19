#
# spec file for package sca-patterns-oes (Version 1.1)
#
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

Name:         sca-patterns-oes
Summary:      Supportconfig Analysis Patterns for OES
Group:        Documentation/SuSE
Distribution: SUSE Linux Enterprise
Vendor:       SUSE Support
License:      GPLv2
Autoreqprov:  on
Version:      1.1
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

%files
%defattr(-,%{patuser},%{patgrp})
%dir /var/opt/%{produser}
%dir %{patdir}
%dir %{patdir}/OES
%dir %{patdir}/OES/all
%dir %{patdir}/OES/oes11all
%dir %{patdir}/OES/oes1all
%dir %{patdir}/OES/oes2all
%dir %{patdir}/OES/oes2sp3
%attr(555,%{patuser},%{patgrp}) %{patdir}/OES/all/*
%attr(555,%{patuser},%{patgrp}) %{patdir}/OES/oes11all/*
%attr(555,%{patuser},%{patgrp}) %{patdir}/OES/oes1all/*
%attr(555,%{patuser},%{patgrp}) %{patdir}/OES/oes2all/*
%attr(555,%{patuser},%{patgrp}) %{patdir}/OES/oes2sp3/*

%prep
%setup -q

%build
make build

%install
make install

%changelog
* Wed Dec 18 2013 jrecord@suse.com
- separated as individual RPM package

