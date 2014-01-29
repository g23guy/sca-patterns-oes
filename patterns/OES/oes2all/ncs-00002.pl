#!/usr/bin/perl -w

# Title:       Confirm the node is in nodes.xml
# Description: Confirm that your node is listed in the nodes.xml file on each cluster server. If it does not exist here then you will have to re-add this node to the cluster.
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
#
#  Authors/Contributors:
#     Jason Record (jrecord@suse.com)
#
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
	PROPERTY_NAME_COMPONENT."=Access",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001434"
);


##############################################################################
# Program execution functions
##############################################################################
sub nodesMissingHost {
	printDebug('> nodesMissingHost');
	my $RCODE = 1;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = '/var/opt/novell/ncs/nodes.xml';
	my @CONTENT = ();
	my $LINE = 0;
	my %HOSTINFO = SDP::SUSE::getHostInfo();
	my $SEARCHFOR = "cn=".$HOSTINFO{'hostname'}.",";

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			if ( /$SEARCHFOR/ ) {
				printDebug("  nodesMissingHost LINE $LINE", $_);
				$RCODE--;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
		$RCODE--;
	}
	printDebug('< nodesMissingHost', "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main
##############################################################################

SDP::Core::processOptions();

	if ( nodesMissingHost() ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "NCS node hostname missing from nodes.xml");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "NCS node hostname found in nodes.xml");
	}

SDP::Core::printPatternResults();
exit;

