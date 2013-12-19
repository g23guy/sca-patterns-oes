#!/usr/bin/perl

# Title:       OES Kernel Security Advisory SUSE-SA:2009:033
# Description: The OES1 kernel was updated to fix a remote code execution security issues, Severity 8 of 10.
# Modified:    2013 Jun 27

##############################################################################
#  Copyright (C) 2013 SUSE LLC
##############################################################################
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#  Authors/Contributors:
#    Jason Record (jrecord@suse.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=Security",
	PROPERTY_NAME_COMPONENT."=Kernel",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_Security",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_Security=http://www.novell.com/linux/security/advisories/2009_33_kernel.html",
	"META_LINK_Doc=http://www.novell.com/documentation/oes/install_linux/data/bxlu3xc.html"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $ADVISORY            = '8';
	my $TYPE                = 'Remote code execution';
	my $CHECKING            = 'OES Kernel';
	my @PKG_CHECKING        = ();
	my $FIXED_IN            = '';
	my %FOUND               = SDP::SUSE::getHostInfo();

	if ( $FOUND{'oes'} ) {
		if ( SDP::SUSE::securitySeverityKernelCheck(SLE9SP1, SLE9SP5, '2.6.5-7.317', $ADVISORY, $TYPE) ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ABORTED: OES Kernel Security Advisory: Outside the kernel scope");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ABORTED: OES Not Installed");
	}
SDP::Core::printPatternResults();

exit;
