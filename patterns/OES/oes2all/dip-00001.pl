#!/usr/bin/perl

# Title:       Duplicate IP Causes Comatose Volume Resource
# Description: A duplicate IP address will cause a volume resource to go comatose
# Modified:    2013 Jun 21

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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Comatose",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007941"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub detectDuplicateIP {
	SDP::Core::printDebug('> detectDuplicateIP', 'BEGIN');
	use constant VR_OFFLINE => 1;
	use constant VR_COMATOSE => 2;
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-ncsvr.txt';
	my $SECTION = '/usr/lib/supportconfig/plugins/ncsvr';
	my @CONTENT = ();
	my $VR = 0;
	my $VR_NAME = '';
	my $NCP_IP = '';
	my $VR_STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $VR ) {
				if ( /Volume Resource: $VR_NAME\s*Offline/i ) {
					$VR_STATE = VR_OFFLINE;
				} elsif ( /Volume Resource: $VR_NAME\s*Comatose/i ) {
					$VR_STATE = VR_COMATOSE;
				} elsif ( /NCP Server:\s\S*\s*Pinged (.*)/i ) {
					$NCP_IP = $1;
					if ( $VR_STATE == VR_OFFLINE ) {
						SDP::Core::updateStatus(STATUS_WARNING, "$VR_NAME will go comatose if onlined, detected duplicate IP $NCP_IP");
						$RCODE++;
					} elsif ( $VR_STATE == VR_COMATOSE ) {
						SDP::Core::updateStatus(STATUS_CRITICAL, "$VR_NAME is comatose, detected duplicate IP $NCP_IP");
						$RCODE++;
					}
				} elsif ( /$VR_NAME Volume Resource Status:/i ) {
					$VR = 0;
					$VR_NAME = '';
					$NCP_IP = '';
					$VR_STATE = 0;
				}
			} elsif ( /(\S*)\sAnalyzing Volume Resource/i ) {
				$VR_NAME = $1;
				$VR = 1;
			} elsif ( /^# File: cat -n \/usr\/lib\/supportconfig\/plugins\/ncsvr/i ) {
				last;
			}
		}
		if ( ! $RCODE ) {
			SDP::Core::updateStatus(STATUS_ERROR, "No Duplicate IP Addresses Found for Offline or Comatose");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: detectDuplicateIP(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< detectDuplicateIP", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	detectDuplicateIP();
SDP::Core::printPatternResults();

exit;

