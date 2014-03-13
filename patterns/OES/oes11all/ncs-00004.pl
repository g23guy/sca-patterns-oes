#!/usr/bin/perl

# Title:       Cluster Resources do not Display
# Description: No output from cluster resources and cluster status commands.
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Display",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008888"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub missingClusterOutput {
	SDP::Core::printDebug('> missingClusterOutput', 'BEGIN');
	my $RCODE = 1; # assume missing output
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'cluster resources';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			next if ( m/^Name/ ); # Skip header
			if ( /\S/ ) { # a non-white space character after the header line indicates display found
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingClusterOutput(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< missingClusterOutput", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::OESLinux::ncsActive() ) {
		if ( missingClusterOutput() ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Missing cluster resource display, make Linux server the master node.");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Cluster resource display found, ignoring output test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Active NCS cluster required, skipping cluster output test");
	}
SDP::Core::printPatternResults();
exit;

