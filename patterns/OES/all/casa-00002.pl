#!/usr/bin/perl

# Title:       Missing CASA Credentials
# Description: The common casa proxy or all casa credentials are missing
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
	PROPERTY_NAME_CATEGORY."=CASA",
	PROPERTY_NAME_COMPONENT."=Proxy",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008568"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub missingCASACredentials {
	my $OSP = $_[0];
	SDP::Core::printDebug('> missingCASACredentials', "OES Patch Level: $OSP");
	my $RCODE = 0;
	my $FILE_OPEN = 'env.txt';
	my $SECTION = 'CASAcli -l';
	my @CONTENT = ();
	my $FOUND = 0;
	my $FOUND_COMMON = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /Command not found or not executible/i ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingCASACredentials(): Command not found: \"$SECTION\" in $FILE_OPEN");				
			} elsif ( /Found 0 credential sets/i ) {
				$RCODE = 1;
				last;
			} elsif ( /Name: common-proxy-casa/ ) {
				$FOUND_COMMON = 1;
				$FOUND++;
			} elsif ( /Name: (.*)/ ) {
				$FOUND++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingCASACredentials(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( ! $FOUND ) {
		$RCODE = 1;
	} elsif ( ! $FOUND_COMMON ) {
		if ( $OSP > 2 ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing CASA Common Proxy Credentials");
			$RCODE = 1;
		}
	}
	SDP::Core::printDebug("< missingCASACredentials", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( missingCASACredentials($HOST_INFO{'oespatchlevel'}) ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Missing CASA Credentials");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Found CASA Credentials");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES Required, skipping CASA test.");
}
SDP::Core::printPatternResults();
exit;

