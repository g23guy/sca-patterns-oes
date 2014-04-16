#!/usr/bin/perl

# Title:       NSS Pools and Pool Resources Fail to Activate or go Comatose
# Description: Migrating an NSS resource to an NCS node results in the resource going comatose, and creating new pools reports CVB has not registered for pool events.
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
	PROPERTY_NAME_CATEGORY."=NCS",
	PROPERTY_NAME_COMPONENT."=NSS Pool",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003560"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub comatoseResource {
	SDP::Core::printDebug('> comatoseResource', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'cluster resources';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /comatose/i ) {
				SDP::Core::printDebug("  comatoseResource PROCESSED", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< comatoseResource", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::SUSE::packageInstalled('novell-cluster-services') && SDP::SUSE::packageInstalled('novell-nss') ) {
	if ( SDP::SUSE::serviceBootstate('novell-ncs') ) {
		SDP::Core::printDebug("  main NCS", "Novell NCS is turned on at boot");
		if ( SDP::SUSE::serviceBootstate('novell-nss') ) {
			SDP::Core::printDebug("  main NSS", "Novell NSS is turned on at boot");
			SDP::Core::updateStatus(STATUS_ERROR, "NCS and NSS are both turned on at boot");
		} else {
			SDP::Core::printDebug("  main NSS", "Novell NSS is turned off at boot");
			if ( comatoseResource() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Probable NSS Pool failure: Comatose resources with NCS on and NSS off at boot");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Potential NSS Pool failure: NCS is on, but NSS is off at boot");
			}
		}
	} else {
		SDP::Core::printDebug("  main NCS", "Novell NCS is turned off at boot");
		SDP::Core::updateStatus(STATUS_ERROR, "Missing Required Service for Pattern Test: novell-ncs");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Missing Required Packages for Pattern Test: novell-cluster-services, novell-nss");
}
SDP::Core::printPatternResults();
exit;

