#!/usr/bin/perl

# Title:       Cannot manage iPrint driver associations
# Description: iPrint CLIENT_ERROR 0x400 when attempting manage driver associations
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

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=Driver",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7007014",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=620199"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub duplicateEmptyDrivers {
	SDP::Core::printDebug('> duplicateEmptyDrivers', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = '/var/opt/novell/iprint/.*/padbtxt.xml';
	my @CONTENT = ();
	my $printerState = 0;
	my $profileState = 0;
	my $emptyDriverNames = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $printerState ) { # I'm already in a <printer> definition
				if ( $profileState ) { # I'm already in a <profile> definition
					if ( m/<drivername><\/drivername>/ ) {
						$emptyDriverNames++;
#						SDP::Core::printDebug("  DRIVER", "emptyDriverNames++ = $emptyDriverNames: $_");
					} elsif ( m/<\/profile>/ ) {
#						SDP::Core::printDebug(" PROFILE OFF", "emptyDriverNames = $emptyDriverNames: $_");
						$profileState = 0;
					}
				} elsif ( m/<\/printer>/ ) {
#					SDP::Core::printDebug("PRINTER OFF", "emptyDriverNames = $emptyDriverNames: $_");
					$printerState = 0;
				} elsif ( m/<profile>/ ) {
#					SDP::Core::printDebug(" PROFILE ON", "emptyDriverNames = $emptyDriverNames: $_");
					$profileState = 1;
				}
			} elsif ( m/<printer>/ ) {
				$printerState = 1;
				$emptyDriverNames = 0;
#				SDP::Core::printDebug("PRINTER ON", "emptyDriverNames = $emptyDriverNames: $_");
			} 
			if ( $emptyDriverNames > 1 ) {
#				SDP::Core::printDebug("ERROR", "emptyDriverNames = $emptyDriverNames: Limit Exceeded");
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: duplicateEmptyDrivers(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< duplicateEmptyDrivers", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( duplicateEmptyDrivers() ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Potential for errors managing printer driver associations, empty driver names detected.");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No empty <drivername> definitions found.");
	}
SDP::Core::printPatternResults();

exit;

