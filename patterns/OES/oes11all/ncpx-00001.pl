#!/usr/bin/perl

# Title:       Lost NCP exports for NSS Volumes
# Description: NCP exports for NSS volumes are lost on OES11SP1 after implementing Patch SLESSP2-Kernel 7277
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
	PROPERTY_NAME_CATEGORY."=NCP",
	PROPERTY_NAME_COMPONENT."=Exports",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011764",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=802874"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub ncpExportFailures {
	SDP::Core::printDebug('> ncpExportFailures', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncp.txt';
	my $SECTION = 'ncpcon.log ';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /IPCServRequest clientErr=-672/ ) {
				SDP::Core::printDebug("  ncpExportFailures PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ncpExportFailures(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< ncpExportFailures", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $KERN_VER = '3.0.58-0.6.2';
if ( SDP::SUSE::compareKernel($KERN_VER) == 0 ) {
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oes'} ) {
		if ( ncpExportFailures() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "NCP exports for NSS volumes have failed, consider a kernel version other than $KERN_VER");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "NCP exports for NSS volumes may fail");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: OES not installed, skipping ncp test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Error: Outside kernel scope, skipping ncp test");
}
SDP::Core::printPatternResults();
exit;


