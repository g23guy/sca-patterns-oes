#!/usr/bin/perl

# Title:       Errors with Windows offline files and Novell CIFS
# Description: Error: The process cannot access the file because it is being used by another process
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
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=CIFS",
	PROPERTY_NAME_COMPONENT."=OpLocks",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005369",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=564946"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub oplocksEnabled {
	SDP::Core::printDebug('> oplocksEnabled', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-cifs.txt';
	my $SECTION = 'novcifs -o';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /Oplocks.*Enabled/i ) {
				SDP::Core::printDebug("  oplocksEnabled PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: oplocksEnabled(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< oplocksEnabled", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $SERVICE_NAME = 'novell-cifs';
	if ( packageInstalled($SERVICE_NAME) ) {
		my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
		if ( $SERVICE_INFO{'running'} ) {
			if ( oplocksEnabled() ) {
				SDP::Core::updateStatus(STATUS_ERROR, "Windows Offline Files will work with CIFS oplocks enabled");
			} else {
				SDP::Core::updateStatus(STATUS_RECOMMEND, "Windows Offline Files will fail, enable CIFS oplocks if you use offline files");
			}
		} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: $SERVICE_NAME not running, skipping test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: $SERVICE_NAME not installed, skipping test");
	}
SDP::Core::printPatternResults();
exit;

