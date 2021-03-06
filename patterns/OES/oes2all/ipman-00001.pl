#!/usr/bin/perl

# Title:       iprintman OpenWBEM4::CIMException Error
# Description: Getting error terminate called after throwing an instance of OpenWBEM4::CIMException when running iprintman
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
	PROPERTY_NAME_COMPONENT."=OpenWBEM",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002331",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=425297"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub iprintmanError {
	SDP::Core::printDebug('> iprintmanError', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = 'iprintman psm';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /terminate called after throwing an instance of.*OpenWBEM4::CIMException.*/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: iprintmanError(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< iprintmanError", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( iprintmanError() ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected iprintman OpenWBEM4::CIMException error");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ABORT: Not errors detected, skipping OpenWBEM4::CIMException");
	}
SDP::Core::printPatternResults();

exit;

