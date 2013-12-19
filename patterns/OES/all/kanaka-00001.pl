#!/usr/bin/perl

# Title:       Kanaka Failed Login
# Description: Cannot login to Kanaka server from Mac or web browser
# Modified:    2013 Jun 20

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

#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)

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
	PROPERTY_NAME_CATEGORY."=Kanaka",
	PROPERTY_NAME_COMPONENT."=Login",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7000140",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=750191"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $RPM_NAME = 'novell-kanaka-engine';
my $VERSION_TO_COMPARE = '2.6';
my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
if ( $RPM_COMPARISON == 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
} elsif ( $RPM_COMPARISON > 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
} else {
	if ( $RPM_COMPARISON >= 0 ) {
		my $XTIER_RPM = 'novell-xtier-core';
		my $XTIER_VERSION = '3.1.8-0.26';
		my $COMPARISON = SDP::SUSE::compareRpm($XTIER_RPM, $XTIER_VERSION);
		if ( $COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $XTIER_RPM Not Installed");
		} elsif ( $COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $XTIER_RPM RPM are Installed");
		} else {
			if ( $COMPARISON < 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Outdated Xtier packages may cause Kanaka login problems");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Xtier package does not conflict with Kanaka");
			}			
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Invalid Kanaka Package Version");
	}			
}
SDP::Core::printPatternResults();
exit;


