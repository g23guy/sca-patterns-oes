#!/usr/bin/perl

# Title:       AFP volume multi-depth folder browse failures
# Description: OES2 novell-afp Unable to browse directories past four levels deep on one volume from a MAC
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
#

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
	PROPERTY_NAME_CATEGORY."=AFP",
	PROPERTY_NAME_COMPONENT."=Volumes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003579",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=484013",
);

##############################################################################
# Local Function Definitions
##############################################################################

sub volumesDefined {
	SDP::Core::printDebug('> volumesDefined', 'BEGIN');
	my $RCODE                    = 0;
	my $HEADER_LINES             = 0;
	my $FILE_OPEN                = 'novell-afp.txt';
	my $SECTION                  = 'afpvols.conf';
	my @CONTENT                  = ();
	my $LINE                     = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ );                  # Skip blank lines
			if ( /.*/ ) {
				SDP::Core::printDebug("  volumesDefined $LINE", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::updateStatus(STATUS_PARTIAL, "AFP Volumes Found: $RCODE");
	SDP::Core::printDebug("< volumesDefined", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $AFPRPM = 'novell-afptcpd';
my %AFP = SDP::SUSE::getServiceInfo('novell-afptcpd');
my $RPMCMP = SDP::SUSE::compareRpm('novell-afptcpd', '1.0.0-0.36');
if ( $RPMCMP == 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "RPM Not Installed: $AFPRPM");
} elsif ( $RPMCMP == 3 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "Multiple RPM Versions Installed: $AFPRPM");
} elsif ( $AFP{'running'} && volumesDefined() ) {
	if ( $RPMCMP <= 0 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "AFP volumes may be suseptible to multi-depth folder browse failures");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "AFP volumes are not suseptible to multi-depth folder browse failure");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "No AFP volumes are defined or AFP is not running");
}
SDP::Core::printPatternResults();
exit;


