#!/usr/bin/perl

# Title:       iPrint Insufficient Rights Message
# Description: Insufficient rights message attempting to manage iPrint on Linux
# Modified:    2013 Jun 25

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
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

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
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=Rights",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005741",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=596774"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $IPRINT_BADV='6.2.20100312-0.6.1';
	my $IPRINT_GOODV='6.2.20100805';

	my $RPM_NAME = 'novell-iprint-server';
	my @RPM_INFO = SDP::SUSE::getRpmInfo($RPM_NAME);
	if ( $#RPM_INFO < 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $#RPM_INFO > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple $RPM_NAME RPMs Installed");
	} else {
		if ( SDP::Core::compareVersions($RPM_INFO[0]{'version'}, $IPRINT_BADV) >= 0 && SDP::Core::compareVersions($RPM_INFO[0]{'version'}, $IPRINT_GOODV) < 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Insufficient rights managing iPrint may occur, update system to apply $RPM_NAME v$IPRINT_GOODV or higher");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Skipping rights check, $RPM_INFO[0]{'name'}-$RPM_INFO[0]{'version'}");
		}
	}
SDP::Core::printPatternResults();

exit;


