#!/usr/bin/perl

# Title:       No information displayed from NCS cluster status command
# Description: Multiple cluster nodes may not show cluster status information
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
	PROPERTY_NAME_CATEGORY."=Cluster",
	PROPERTY_NAME_COMPONENT."=Display",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005828",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=598029"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub ncsClusterRunning {
	SDP::Core::printDebug('> ncsClusterRunning', 'BEGIN');
	my $RCODE = 0;
	my $SERVICE_NAME = 'novell-ncs';
	my $OES2SP2 = 0;
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	$OES2SP2 = 1 if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'}, '2.0.2') == 0 );
	$RCODE++ if ( $SERVICE_INFO{'running'} && $OES2SP2 );
	SDP::Core::printDebug("< ncsClusterRunning", "Returns: $RCODE");
	return $RCODE;
}

sub noClusterStatus {
	SDP::Core::printDebug('> noClusterStatus', 'BEGIN');
	my $RCODE = 1;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'cluster resources';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			next if ( /Name.*State.*Node.*Lives/i ); # skip header
			if ( /^\S+/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: noClusterStatus(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< noClusterStatus", "Returns: $RCODE");
	return $RCODE;
}

sub patchApplied {
	SDP::Core::printDebug('> patchApplied', 'BEGIN');
	my $RCODE = 0;
	my $RPM_NAME = 'novell-cluster-services';
	my $VERSION_TO_COMPARE = '1.8.7.642-0.5';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		$RCODE++ if ( $RPM_COMPARISON >= 0 );
	}
	SDP::Core::printDebug("< patchApplied", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( ncsClusterRunning() ) {
		if ( noClusterStatus() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing NCS cluster status");
		} else {
			if ( patchApplied() ) {
				SDP::Core::updateStatus(STATUS_ERROR, "Patched applied for missing NCS cluster status");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Susceptible to missing NCS cluster status");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: An active OES2 SP2 NCS cluster required for analysis");
	}
SDP::Core::printPatternResults();

exit;

