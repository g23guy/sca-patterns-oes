#!/usr/bin/perl

# Title:       Check for magic got poked error message
# Description: NSS free called with a pointer which is not allocated with NSS malloc.
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
	PROPERTY_NAME_CATEGORY."=LUM",
	PROPERTY_NAME_COMPONENT."=Volumes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006627",
	"META_LINK_TID2=http://www.suse.com/support/kb/doc.php?id=3374462",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=630467"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub magicPoked {
	SDP::Core::printDebug('> magicPoked', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /kernel:\s*Magic got poked and is 0x.*/i ) {
				SDP::Core::printDebug("  magicPoked PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: magicPoked(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< magicPoked", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} > 1 ) {
	if ( magicPoked() ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "NSS malloc issue, provide NTS with a kernel core dump");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: No \"Magic got poked\" errors observed");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES NOT Installed on $HOST_INFO{'hostname'}");
}
SDP::Core::printPatternResults();
exit;

