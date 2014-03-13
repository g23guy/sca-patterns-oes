#!/usr/bin/perl

# Title:       novell-afptcpd crashes when authenitcating from a MAC
# Description: Versions of novell-afptcpd might report "unused" as soon as a MAC workstation authenticates to the server.
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
	PROPERTY_NAME_CATEGORY."=AFP",
	PROPERTY_NAME_COMPONENT."=Authentication",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005838",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=581533"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub errorFound {
	SDP::Core::printDebug('> errorFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /afptcpd.*zAFPCreate: zCreate failed for .DS_Store with error - 20851/i ) {
				SDP::Core::printDebug("  errorFound PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: errorFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< errorFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	my $RPM_NAME = 'novell-afptcpd';
	my $VERSION_TO_COMPARE = '1.1.0-0.13.1';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		if ( $RPM_COMPARISON == 0 ) {
			if ( errorFound() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "MAC authentication induced AFP failures");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Susceptible to MAC authentication induced AFP failures");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "MAC authentication induced AFP failures not observed");
		}			
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "OES NOT Installed on $HOST_INFO{'hostname'}, skipping AFP MAC test");
}
SDP::Core::printPatternResults();
exit;

