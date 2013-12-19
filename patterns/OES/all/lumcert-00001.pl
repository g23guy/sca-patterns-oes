#!/usr/bin/perl

# Title:       Novell LUM LDAPS Connection Test
# Description: Checks for a valid LDAPS connection and LUM certificates.
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
	PROPERTY_NAME_CATEGORY."=LUM",
	PROPERTY_NAME_COMPONENT."=Certs",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3401691"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getDirFile {
	SDP::Core::printDebug('>> getDirFile');
	my $RCODE = '';
	my $FILE_OPEN = 'etc.txt';
	my $SECTION = 'nam.conf';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /preferred-server=(.*)/ ) {
				SDP::Core::printDebug("  getDirFile PROCESSING", $_);
				$RCODE = "\.$1\.der";
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getDirFile(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("<< getDirFile", "Returns: '$RCODE'");
	return $RCODE;
}

sub ldapsFailure {
	SDP::Core::printDebug('> ldapsFailure');
	my $RCODE = 0;
	my $DER_FILE = getDirFile();
	my $FILE_OPEN = 'novell-lum.txt';
	my $SECTION = "ldapsearch.*-e.*/var/lib/novell-lum/$DER_FILE.*-s base";
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) { # try the OES2 LUM path
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^LDAPS Connection.*Success/i ) {
				SDP::Core::updateStatus(STATUS_ERROR, "$_");
				$RCODE = 0;
				last;
			} elsif ( /^LDAPS Connection.*FAILED/i ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Check LUM Certificates; $_");
				$RCODE = 1;
				last;
			}
		}
	} else { # try the older OES1 LUM path
		$SECTION = "ldapsearch.*-e.*/var/nam/$DER_FILE.*-s base";
		@CONTENT = ();
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /^LDAPS Connection.*Success/i ) {
					SDP::Core::updateStatus(STATUS_ERROR, "$_");
					$RCODE = 0;
					last;
				} elsif ( /^LDAPS Connection.*FAILED/i ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "Check LUM Certificates; $_");
					$RCODE = 1;
					last;
				}
			}
		} else { # they're all gone
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing LDAPS LUM Certificate .DER file");
		}
	}
	SDP::Core::printDebug("< ldapsFailure", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
ldapsFailure();
SDP::Core::printPatternResults();
exit;

