#!/usr/bin/perl

# Title:       NCS Poison Pill Detection
# Description: Check for poison pills in the NCS cluster
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
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

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
	PROPERTY_NAME_CATEGORY."=SBD",
	PROPERTY_NAME_COMPONENT."=Poison Pill",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_MISC=http://www.novell.com/documentation/oes2/clus_admin_lx/data/poisonpill.html"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub searchForPoisonPills {
	SDP::Core::printDebug('> searchForPoisonPills', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my %PILLED_NODES = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /.*cluster stability.*sent a poison pill.*\[(.*)\]/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$PILLED_NODES{$1} = 1;
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: searchForPoisonPills(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		my @NODES = keys(%PILLED_NODES);
		SDP::Core::updateStatus(STATUS_WARNING, "Nodes sent a Poison Pill: @NODES");		
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No recent poison pills detected.");		
	}
	SDP::Core::printDebug("< searchForPoisonPills", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::packageInstalled('novell-cluster-services') ) {
		searchForPoisonPills();
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES NCS required, skipping poison pill test.");
	}
SDP::Core::printPatternResults();

exit;

