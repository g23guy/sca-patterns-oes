#!/usr/bin/perl

# Title:       wbinfo -u fails on DSFW server
# Description: Running the command wbinfo -u returns "Error looking up domain users".
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
	PROPERTY_NAME_CATEGORY."=DSFW",
	PROPERTY_NAME_COMPONENT."=Lookup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004943"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkDSFWTimeOut {
	SDP::Core::printDebug('> checkDSFWTimeOut', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'samba.txt';
	my $SECTION = '/var/log/samba/log.winbindd';
	my @CONTENT = ();
	my $LINE = 0;
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ ); # Skip blank lines
			if ( $STATE ) { # look for time out only if the query_user_list was found in the log file
				if ( /query_user_list ads_search: Timed out|query_user_list ads_search: Time limit exceeded/i ) {
					SDP::Core::printDebug("LINE $LINE", $_);
					$RCODE++;
					last;
				} else {
					$STATE = 0;
				}
			} else {
				if ( /nsswitch\/winbindd_ads.c:query_user_list/i ) {
					SDP::Core::printDebug("LINE $LINE", $_);
					$STATE = 1; # now look for the timeout
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_WARNING, "DSFW user lookup timeout observed");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "wbinfo time out not observed");
	}
	SDP::Core::printDebug("< checkDSFWTimeOut", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	checkDSFWTimeOut();
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ABORT: DSFW time out error, OES not installed.");
}
SDP::Core::printPatternResults();
exit;

