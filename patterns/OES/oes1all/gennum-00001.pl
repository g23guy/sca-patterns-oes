#!/usr/bin/perl

# Title:       iPrint Unable to Read Generation Number
# Description: iPrint Linux Print Manager unable to read generation number
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
	PROPERTY_NAME_COMPONENT."=Start",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7000933",
	"META_LINK_TID2=http://www.novell.com/support/kb/doc.php?id=3006957"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub failedGenNumRead {
	SDP::Core::printDebug('> failedGenNumRead', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = 'ipsmd.log';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /FATAL The iPrint Manager was unable to read the generation number.*Error.*506D000C/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: failedGenNumRead(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< failedGenNumRead", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( failedGenNumRead() ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "iPrint Linux Print Manager unable to read generation number");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "iPrint: No FATAL generation number errors detected");
	}
SDP::Core::printPatternResults();

exit;

