#!/usr/bin/perl

# Title:       CIFS ERROR: CODIR: lock_dircache_entry failed
# Description: Checks for CIFS ERROR: CODIR: lock_dircache_entry failed
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
	PROPERTY_NAME_CATEGORY."=CIFS",
	PROPERTY_NAME_COMPONENT."=Files",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007847",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=670389"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub errorCodeFound {
	SDP::Core::printDebug('> errorCodeFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-cifs.txt';
	my $SECTION = 'cifs.log';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /ERROR: CODIR: lock_dircache_entry failed/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: errorCodeFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< errorCodeFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $RPM_NAME = 'novell-cifs';
my $VERSION_TO_COMPARE = '1.2.0-0.46';
my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
if ( $RPM_COMPARISON == 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
} elsif ( $RPM_COMPARISON > 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
} else {
	if ( $RPM_COMPARISON == 0 ) {
		if ( errorCodeFound() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Update System - Detected lock_dircache_entry, which may be cause of file access errors");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "Update System - File access may be denied if Trustee is set on parent folder");
		}			
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR cifs version with no lock_dircache_entry, punt");
	}			
}
SDP::Core::printPatternResults();
exit;

