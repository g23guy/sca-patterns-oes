#!/usr/bin/perl

# Title:       Creating New NCS Cluster Resource Fails
# Description: Looks for insufficient access creating NCS resources.
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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Create",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005195"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub searchLogsforAccess {
	SDP::Core::printDebug('> searchLogsforAccess', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $LINE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /ncs-configd: createVolumeResource failed.*-672.*Insufficient access/i ) {
				SDP::Core::printDebug("LINE $LINE", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Access issue observed for cluster resource creation");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "CASA: Cluster resource creation failure not observed");
	}
	SDP::Core::printDebug("< searchLogsforAccess", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oes'} ) {
		if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'}, '2.0.2') == 0 && SDP::SUSE::packageInstalled('novell-cluster-services') ) {
			searchLogsforAccess();
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2 Clustering not installed, skipping CASA test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES not installed, skipping CASA test");
	}
SDP::Core::printPatternResults();
exit;

