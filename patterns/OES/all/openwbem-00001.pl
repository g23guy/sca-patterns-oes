#!/usr/bin/perl

# Title:       Error parsing Service Description XML Document
# Description: /usr/share/omc/svcinfo.d/novell-vigil.xml MSG: Invalid file permission
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
	PROPERTY_NAME_CATEGORY."=OpenWBEM",
	PROPERTY_NAME_COMPONENT."=Files",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008230",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=658558"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub vigilError {
	SDP::Core::printDebug('> vigilError', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /openwbem.*Error parsing Service Description XML Document.*novell-vigil\.xml.*Invalid file permission for XML file/i ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: vigilError(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< vigilError", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} > 1 && $HOST_INFO{'oespatchlevel'} > 1 ) {
	if ( vigilError() ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected OpenWBEM Error, Invalid novell-vigil.xml File Permissions");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "IGNORE: Missing OpenWBEM novell-vigil.xml Error");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2SP2 or higher, skipping OpenWBEM test");
}
SDP::Core::printPatternResults();
exit;

