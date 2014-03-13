#!/usr/bin/perl

# Title:       Trustee file contributes to NDSD segfault
# Description: OES2 SP3 - NDSD crashes in NCP when updating the Volume trustee file
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
	PROPERTY_NAME_CATEGORY."=NCP",
	PROPERTY_NAME_COMPONENT."=Trustee",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007927",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=666582"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub affectedNCPVersion {
	SDP::Core::printDebug('> affectedNCPVersion', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncp.txt';
	my $SECTION = 'ncpcon version';
	my @CONTENT = ();
	use constant MIN_AFFECTED_VERSIONS => 3;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^\[libncpengine\]\s*2010-12-21_.*-\.2637/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			} elsif ( /^\[ncp2nss\]\s*2010-11-29_.*-\.1658/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			} elsif ( /^\[libnrm2ncp\]\s*2010-11-29_.*-\.1658/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: affectedNCPVersion(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE < MIN_AFFECTED_VERSIONS ) {
		SDP::Core::updateStatus(STATUS_PARTIAL, "NCP component versions don't all match");
		$RCODE = 0;
	}
	SDP::Core::printDebug("< affectedNCPVersion", "Returns: $RCODE");
	return $RCODE;
}

sub segfaultErrorsFound {
	SDP::Core::printDebug('> segfaultErrorsFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /kernel.*ndsd.*segfault at 0000000000000121 rip 00002aaaaab03fde rsp.*error 4/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			} elsif ( /kernel.*ndsd.*segfault at 0000000000000121 rip 00002aaaaab03fde rsp.*error 4/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: segfaultErrorsFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< segfaultErrorsFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( $HOST_INFO{'oesmajor'} = 2 && $HOST_INFO{'oesminor'} = 3 ) {
		if ( affectedNCPVersion() ) {
			if ( segfaultErrorsFound() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Detected NCP related NDSD segfault");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Detected Potential for NCP related NDSD segfaults");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Affected NCP Version not Detected, skipping segfault test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2 SP3 Required, skipping segfault test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES Required, skipping segfault test");
}
SDP::Core::printPatternResults();
exit;

