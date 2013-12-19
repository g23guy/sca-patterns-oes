#!/usr/bin/perl

# Title:       Invalid NSS Volume IDs
# Description: Cluster resource mounts in NSS but Fails to mount in NCP with no errors.
# Modified:    2013 Sep 27
#
##############################################################################
# Copyright (C) 2013 SUSE LLC
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)
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
"META_CLASS=OES",
"META_CATEGORY=NSS",
"META_COMPONENT=Volume ID",
"PATTERN_ID=$PATTERN_ID",
"PRIMARY_LINK=META_LINK_TID",
"OVERALL=$GSTATUS",
"OVERALL_INFO=NOT SET",
"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7013354",
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getInvalidVolumeIDs {
	SDP::Core::printDebug('> getInvalidVolumeIDs', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'novell-ncs.txt';
	my @CONTENT = ();
	my @INVALID_VOLS = ();

	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			if ( /^exit_on_error ncpcon mount (.*)/ ) {
#				SDP::Core::printDebug("Validate", $_);
				@LINE_CONTENT = split(/=/, $1);
				if ( $LINE_CONTENT[1] lt 0 || $LINE_CONTENT[1] gt 254 ) {
#					SDP::Core::printDebug(" Invalid", "@LINE_CONTENT");
					push(@INVALID_VOLS, $LINE_CONTENT[0]);
#				} else {
#					SDP::Core::printDebug(" Valid", "@LINE_CONTENT");
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getInvalidVolumeIDs(): Cannot find file $FILE_OPEN");
	}
	SDP::Core::printDebug("< getInvalidVolumeIDs", "Returns: @INVALID_VOLS");
	return @INVALID_VOLS;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my @VOLS = getInvalidVolumeIDs();
my $VOL_COUNT = scalar @VOLS;
if ( $VOL_COUNT > 0 ) {
	SDP::Core::updateStatus(STATUS_CRITICAL, "Detected Invalid NSS Volume ID in load script for: @VOLS");
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "No invalid NSS volume IDs found");
}
SDP::Core::printPatternResults();
exit;


