#!/usr/bin/perl

# Title:       NSS volumes dismount due to Snapshot
# Description: File Level enabled (Copy on Write) may cause NSS volumes to randomly dismount
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=NSS",
	PROPERTY_NAME_COMPONENT."=Snapshots",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003563",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=357341"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my @VOLUMES = SDP::OESLinux::getNssVolumes();
my $i;
my $ATTR;
my $SUSPECT_VOLUMES = '';
# TODO
# When the issue is fixed, add a package version check for package(s) where the problem exists
if ( @VOLUMES ) { # NSS volumes exist
	foreach $i (0 .. $#VOLUMES) {
		SDP::Core::printDebug("CHECKING VOLUME", $VOLUMES[$i]{'name'});
		for $ATTR ( keys %{ $VOLUMES[$i] } ) { # Check each key for defined attributes
			SDP::Core::printDebug(" Testing Key", $ATTR);
			if ( $ATTR =~ /Snapshot file-level.*Copy On Write/i ) { # The volume has the snapshot file-level (copy on write) attribute
				$SUSPECT_VOLUMES = $SUSPECT_VOLUMES . $VOLUMES[$i]{'name'} . ' ';
				SDP::Core::printDebug("  Key Found", 'Exit Volume Search');
				last;
			}
		}
	}
	if ( $SUSPECT_VOLUMES ) {
		$SUSPECT_VOLUMES =~ s/\s+$//;
		SDP::Core::updateStatus(STATUS_WARNING, "Volume(s): $SUSPECT_VOLUMES" . ". One or more may deactivate due to snapshot file-level copy on write");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No volumes defined with snapshot file-level copy on write");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "No NSS volumes found");
}
SDP::Core::printPatternResults();
exit;


