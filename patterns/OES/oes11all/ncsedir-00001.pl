#!/usr/bin/perl

# Title:       NCS eDirectory Monitor Script
# Description: Detects unstable ndsstat monitor command
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
use File::Basename;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Monitor",
	PROPERTY_NAME_COMPONENT."=Script",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7007370"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkEdirMonitor {
	my $SECTION = $_[0];
	SDP::Core::printDebug('> checkEdirMonitor', $SECTION);
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /ndsstat|ndsd status/ ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkEdirMonitor(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkEdirMonitor", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $FILE_OPEN = 'novell-ncs.txt';
	my @FILE_SECTIONS = ();
	my $SECTION = '';
	my @SCRIPTS = ();

	if ( SDP::Core::listSections($FILE_OPEN, \@FILE_SECTIONS) ) {
		foreach $SECTION (@FILE_SECTIONS) {
			if ( $SECTION =~ m/rpm not installed/i ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: NCS Not Installed");
			} elsif ( $SECTION =~ m/\/ncs\/.*\.monitor$/ ) {
				if ( checkEdirMonitor($SECTION) ) {
					my $FILENAME = File::Basename::basename($SECTION);
					push(@SCRIPTS, $FILENAME);
				}
			}
		}
		SDP::Core::printDebug("SCRIPTS", scalar @SCRIPTS . " - @SCRIPTS");
		if ( scalar @SCRIPTS > 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Unstable NCS resource montior scripts with eDirectory: @SCRIPTS");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Stable NCS resource montior scripts with eDirectory");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: main(): No sections found in $FILE_OPEN");
	}

SDP::Core::printPatternResults();
exit;


