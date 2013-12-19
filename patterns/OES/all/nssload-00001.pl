#!/usr/bin/perl

# Title:       NSS error loading modules
# Description: Checks for NSS module load errors
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

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=NSS",
	PROPERTY_NAME_COMPONENT."=Modules",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005015"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub loadFailedNSS {
	SDP::Core::printDebug('> loadFailedNSS', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'boot.txt';
	my $SECTION = 'boot.msg';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $LINE = 0;
	my $STATE = 0;
	my $NSS_LOAD_ATTEMPTED = 0;
	my $DRV_MISSING = '';

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /ERROR: Cannot find (.*)\.ko/i ) {
					$DRV_MISSING = $1;
					SDP::Core::printDebug('  loadFailedNSS MISSING DRIVER', "$DRV_MISSING");
					$RCODE++;
					last;
				} elsif ( /NSS is running/i ) { # nothing more to check
					$STATE = 0;
					last;
				}
			} elsif ( /Starting Novell Storage Services/i ) {
				$STATE = 1;
				$NSS_LOAD_ATTEMPTED = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "NSS Failed to Load, Missing Driver: $DRV_MISSING");
	} else {
		if ( $NSS_LOAD_ATTEMPTED ) {
			if ( $STATE ) {
				SDP::Core::updateStatus(STATUS_WARNING, "NSS did not load properly");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: NSS did not attempt to load, skipping load test");
		}
	}
	SDP::Core::printDebug("< loadFailedNSS", "Returns: $RCODE");
	return $RCODE;
}

sub checkMissingPackages {
	SDP::Core::printDebug('> checkMissingPackages', 'BEGIN');
	my $RCODE = 0;
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	my @LINE_CONTENT = split(/-/, $HOST_INFO{'kernel'});
	my $KERN_TYPE = pop(@LINE_CONTENT);
	SDP::Core::printDebug('KERNEL TYPE', $KERN_TYPE);
	my @RPMS_NEEDED = ("nss-kmp-$KERN_TYPE", "novell-zapi-kmp-$KERN_TYPE", "novell-nwmpk-kmp-$KERN_TYPE", "adminfs-kmp-$KERN_TYPE");
	@LINE_CONTENT = ();
	foreach my $RPM (@RPMS_NEEDED) { # check to see if each NSS required package is installed
		if ( ! SDP::SUSE::packageInstalled("$RPM") ) {
			push(@LINE_CONTENT, $RPM);
			$RCODE++;
		}
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "NSS Fails to Load, Missing Packages: @LINE_CONTENT");
	}

	SDP::Core::printDebug("< checkMissingPackages", "Returns: $RCODE");
	return $RCODE;
}
##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::SUSE::packageInstalled('novell-nss') ) {
	if ( loadFailedNSS() ) {
		checkMissingPackages();
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "NSS loaded successfully");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Error: NSS not installed, skipping load test");
}
SDP::Core::printPatternResults();
exit;

