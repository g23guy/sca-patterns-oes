#!/usr/bin/perl

# Title:       Cluster DN case in does not match cluster edirectory DN
# Description: Not having the correct case in the clstrlib.conf file will case "NDS Sync" status of new cluster resources.
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
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

#  Authors/Contributors:
#   Juston Mortenson (jmortenson@novell.com)

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
	PROPERTY_NAME_CATEGORY."=Cluster DN",
	PROPERTY_NAME_COMPONENT."=Matching",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001394",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=427867"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub clusterdn {
	printDebug('>', 'clusterdn function');
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'ncsldapCheck.py';
	my @CONTENT = ();
	my $SEARCHFOR = 'ClusterDN';
	my $LINE = 0;
	my $CLUSTERDN = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			if ( /^$SEARCHFOR/ ) {
				printDebug("LINE $LINE", $_);
   			     (undef, $CLUSTERDN) = split (/:/,$_);
				printDebug ("The cluster DN is ", $CLUSTERDN);
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	printDebug("RETURN", $CLUSTERDN);
	printDebug('<Can not find', $SEARCHFOR);
	return $CLUSTERDN;
}


sub returned_cluster_dn {
	printDebug('>', 'returned_cluster_dn');
	my $FILE_OPEN   = 'novell-ncs.txt';
	my $SECTION     = 'ncsldapCheck.py';
	my @CONTENT     = ();
	my $SEARCHFOR   = 'Returned Cluster DN';
	my $LINE        = 0;
	my $RETCLUSTERDN        = "";

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			if ( /^$SEARCHFOR/ ) {
				printDebug("LINE $LINE", $_);
   			     (undef, $RETCLUSTERDN) = split (/:/,$_);
				printDebug ("The retcluster DN is ", $RETCLUSTERDN);
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	printDebug("RETURN", $RETCLUSTERDN);
	printDebug('<Can not find', $SEARCHFOR);
	return $RETCLUSTERDN;
}


##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $CLUSTERDN=clusterdn();
printDebug ("  main cluster DN is", $CLUSTERDN);
my $RETCLUSTERDN=returned_cluster_dn();
printDebug ("  main RETcluster DN is", $RETCLUSTERDN);
if ( $CLUSTERDN ne $RETCLUSTERDN ) {
	SDP::Core::updateStatus(STATUS_CRITICAL, "The Cluster DN (from /etc/opt/novell/ncs/clstrlib.conf) does not match the cluster edirectory DN exactly");		
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "The Cluster DN (from /etc/opt/novell/ncs/clstrlib.conf) matches the cluster edirectory DN exactly");
}
SDP::Core::printPatternResults();
exit;


