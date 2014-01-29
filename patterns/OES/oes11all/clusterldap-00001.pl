#!/usr/bin/perl

# Title:       Confirm that the cluster is communicating via LDAP
# Description: Check ncsldapCheck.py output for LDAP communication.  If it is not there then clstrlib.conf is incorrect.
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
	PROPERTY_NAME_CATEGORY."=Migration",
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001434"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub check_ldap_connection {
	SDP::Core::printDebug('>', 'check_ldap_connection');
	my $RCODE                    = 0;
	my $FILE_OPEN                = 'novell-ncs.txt';
	my $SECTION                  = 'ncsldapCheck.py';
	my @CONTENT                  = ();
	my @LINE_CONTENT             = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ );                   # Skip blank lines
			if ( /Can\'t contact LDAP server/i ) {
				SDP::Core::printDebug("LINE", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "The cluster is not able to connect to the LDAP server as specified in the clstrlib.conf file");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "The cluster is able to connect to the LDAP server as specified in the clstrlib.conf file");
	}
	SDP::Core::printDebug("< Returns: $RCODE", 'check_ldap_connection');
	return $RCODE;
}


##############################################################################
# Main Program Execution
##############################################################################


SDP::Core::processOptions();
check_ldap_connection();
SDP::Core::printPatternResults();
exit;


