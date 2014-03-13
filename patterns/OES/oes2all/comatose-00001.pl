#!/usr/bin/perl

# Title:       Troubleshooting Comatose Cluster Resources
# Description: When a resource fails to load on an NCS node, it can be marked comatose. This pattern checks for comatose resources.
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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Comatose",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7001397",
	"META_LINK_TID2=http://www.novell.com/support/kb/doc.php?id=7001433"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub foundComatoseResources {
	SDP::Core::printDebug('> foundComatoseResources', 'BEGIN');
	use constant RESOURCE => 0;
	use constant STATE => 1;
	use constant NODE => 2;
	my $RCODE = 0; # Assume no comatose resources found
	my $HEADER_LINES = 3;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'cluster resources';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $LINE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( $LINE < $HEADER_LINES ); # Skip header lines
			next if ( /^\s*$/ );                  # Skip blank lines
			@LINE_CONTENT = split(/\s+/, $_);
			if ( $LINE_CONTENT[STATE] =~ /comatose/i ) {
				SDP::Core::printDebug("LINE $LINE", $_);
				SDP::Core::updateStatus(STATUS_CRITICAL, "Comatose NCS Resource: $LINE_CONTENT[RESOURCE] on node $LINE_CONTENT[NODE]");
				$RCODE++;
			} elsif ( $LINE_CONTENT[STATE] =~ /offline/i ) {
				SDP::Core::updateStatus(STATUS_PARTIAL, "NCS Resource: $LINE_CONTENT[RESOURCE], $LINE_CONTENT[STATE]");
			} else {
				SDP::Core::updateStatus(STATUS_PARTIAL, "NCS Resource: $LINE_CONTENT[RESOURCE], $LINE_CONTENT[STATE] on node $LINE_CONTENT[NODE]");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< foundComatoseResources", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::serviceStatus('novell-ncs.txt', 'novell-ncs') > 0 ) { # OES1 does not support novell-ncs status command
		SDP::Core::updateStatus(STATUS_ERROR, "NCS is not running");
	} elsif ( ! foundComatoseResources() ) {
		SDP::Core::updateStatus(STATUS_ERROR, "No Comatose NCS Resources Found");
	}
SDP::Core::printPatternResults();

exit;

