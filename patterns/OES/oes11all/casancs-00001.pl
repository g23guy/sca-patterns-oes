#!/usr/bin/perl

# Title:       Lost CASA credentials for NCS
# Description: CASA credentials were lost and need to be recreated
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
	PROPERTY_NAME_CATEGORY."=Migration",
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005275",
	"META_LINK_TID2=http://www.suse.com/support/kb/doc.php?id=7008568"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub serviceFailure {
	my $SERVICE_NAME = $_[0];
	SDP::Core::printDebug('> serviceFailure', "Name: $SERVICE_NAME");
	my $RCODE = 0;
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) { # service is turned on for runlevel
		if ( $SERVICE_INFO{'running'} < 1 ) { # service is not running as expected
			$RCODE = 1;
		}
	}
	SDP::Core::printDebug("< serviceFailure", "Returns: $RCODE");
	return $RCODE;
}

sub checkingCASACredentials {
	my $CASA = $_[0];
	my $PROD = $_[1];
	SDP::Core::printDebug('> checkingCASACredentials', "CASA: $CASA, Product: $PROD");
	my $RCODE = 0;
	my $FILE_OPEN = 'env.txt';
	my $SECTION = 'CASAcli -l';
	my @CONTENT = ();
	my $MISSING_COMMON = 1;
	my $MISSING_NAME = 1;
	my $CPXU = 'common-proxy-user';

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /Command not found or not executible/i ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkingCASACredentials(): Command not found: \"$SECTION\" in $FILE_OPEN");				
			} elsif ( /Name: common-proxy-casa/i ) {
				$MISSING_COMMON = 0;
			} elsif ( /Name:\s*$CASA/ ) {
				$MISSING_NAME = 0;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkingCASACredentials(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oesmajor'} >= 2 && $HOST_INFO{'oespatchlevel'} >= 3 ) { # >= OES2 SP3
		if ( $MISSING_NAME ) {
			if ( $MISSING_COMMON ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "$PROD Down; Missing CASA credentials");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "$PROD Down; CASA Credentials Found: $CPXU, Missing: $CASA; Move to $CPXU.");
			}
		} else {
			if ( $MISSING_COMMON ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "$PROD Down; Missing $CPXU CASA credentials");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "$PROD Down; CASA Credentials Found: $CPXU, $CASA; Validate");
			}
		}
	} else {
		if ( $MISSING_NAME ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "$PROD Down; CASA Credentials Missing: $CASA; Recreate");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "$PROD Down; CASA Credentials Found: $CASA; Validate");
		}
	}
	SDP::Core::printDebug("< checkingCASACredentials", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $SERVICE_NAME = 'novell-ncs';
if ( serviceFailure($SERVICE_NAME) ) {
	my $CASA_NAME = 'NovellClusterServices.Novell';
	my $PROD_NAME = 'Novell NCS';
	checkingCASACredentials($CASA_NAME, $PROD_NAME);
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Service hasn't failed, skipping CASA test.");
}
SDP::Core::printPatternResults();
exit;

