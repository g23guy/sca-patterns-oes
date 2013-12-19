#!/usr/bin/perl

# Title:       iPrint user/group configuration
# Description: Confirms iprint user and group on psm directories
# Modified:    2013 Jun 25

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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=User",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003592"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkPsmDirectoryOwnership {
	SDP::Core::printDebug('> checkPsmDirectoryOwnership', 'BEGIN');
	my $RCODE = 0;
	my $LINE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = '/var/opt/novell/iprint/';
	my @CONTENT = ();
	my @BADCONFIG = ();
	my $STATE = 0;
	use constant USER => 2;
	use constant GROUP => 3;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^total/ ) { # abort after the 2nd total line
					last;
				} elsif ( /\.psm$/ ) {
					SDP::Core::printDebug("PROCESSING", $_);
					@LINE_CONTENT = split(/\s+/, $_);
					if ( "$LINE_CONTENT[USER]" ne "iprint" || "$LINE_CONTENT[GROUP]" ne "iprint" ) {
						for (my $i=0; $i<7; $i++) { shift(@LINE_CONTENT); }
						my $BAD_DIR = "$SECTION@LINE_CONTENT";
						SDP::Core::printDebug(" PUSH", "$BAD_DIR");
						push(@BADCONFIG, "$BAD_DIR");
					}
				}
			} elsif ( /^total/ ) {
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkPsmDirectoryOwnership(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$RCODE = scalar @BADCONFIG;
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected iPrint User/Group Configuration Issue: @BADCONFIG");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Valid iPrint User/Group Configuration in $SECTION*\.psm");
	}
	SDP::Core::printDebug("< checkPsmDirectoryOwnership", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $IPNCS = SDP::OESLinux::iPrintClustered();
	if ( $IPNCS > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: iPrint is Clustered, skipping psm test");
	} elsif ( $IPNCS < 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Invalid iPrint Cluster Configuration, skipping psm test");
	} else {
		checkPsmDirectoryOwnership();
	}
SDP::Core::printPatternResults();

exit;

