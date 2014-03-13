#!/usr/bin/perl

# Title:       Suggest NCS Volume Resource Validation Plugin
# Description: Suggest as needed the NCS Volume Resource Validation Plugin
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
	PROPERTY_NAME_CATEGORY."=Volume",
	PROPERTY_NAME_COMPONENT."=Plugin",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_CoolSolution",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_CoolSolution=http://www.novell.com/communities/node/2332/supportconfig-linux",
	"META_LINK_Downloads=http://download.opensuse.org/repositories/Novell:/NTS/SLE_11_SP2/noarch/"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub volumeResources {
	SDP::Core::printDebug('> volumeResources', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'ncsldapCheck.py';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^\s*type: nCSVolumeResource/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: volumeResources(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< volumeResources", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::packageInstalled('novell-cluster-services') ) {
		my $RPM_NAME = 'supportutils-plugin-ncs';
		my $VERSION_TO_COMPARE = '1.0-5.1';
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
		if ( $RPM_COMPARISON == 2 || $RPM_COMPARISON > 2 ) {
				if ( volumeResources() ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "The supportutils-plugin-ncs is required for additional clustered volume resource analysis");
				} else {
					SDP::Core::updateStatus(STATUS_RECOMMEND, "Consider installing the NCS Volume Resource Plugin (supportutils-plugin-ncs)");
				}
		} else {
			if ( $RPM_COMPARISON >= 0 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "NCS Volume Resource Plugin Installed");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Update NCS Volume Resource Plugin for better Analysis");
			}			
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: NCS not installed, skipping NCSVR check");
	}
SDP::Core::printPatternResults();
exit;

