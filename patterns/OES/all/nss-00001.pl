#!/usr/bin/perl

# Title:       Single Drive NSS Pool Creation Error
# Description: NSS pool creation on single drive fails with EVMS free extend error, disk not managed by EVMS
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
	PROPERTY_NAME_CATEGORY."=NSS",
	PROPERTY_NAME_COMPONENT."=Pools",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3310620"
);
my %PARTITION = ();

##############################################################################
# Local Function Definitions
##############################################################################

sub singleDisk {
	SDP::Core::printDebug('> singleDisk', 'BEGIN');
	my $RCODE = 1;
	my $LINE = 0;
	my $HEADER_LINES = 2;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'fs-diskio.txt';
	my $SECTION = '/proc/partitions';
	my @CONTENT = ();
	my %DISKS = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( $LINE < $HEADER_LINES ); # Skip header lines
			next if ( m/^\s*$/ ); # Skip blank lines
			s/^\s*//;
			@LINE_CONTENT = split(/\s+/, $_);
			my $PART = $LINE_CONTENT[3];
			if ( $PART =~ m/sd\D+\d+/ ) {
				SDP::Core::printDebug("  singleDisk PART", $PART);
				$PARTITION{$PART} = 1;
				my $DISK = $PART;
				$DISK =~ s/\d+$//;
				$DISKS{$DISK} = 1;
			} elsif ( $PART =~ m/c\d*d\d*p\d*/ ) {
				SDP::Core::printDebug("  singleDisk PART", $PART);
				$PARTITION{$PART} = 1;
				my $DISK = $PART;
				$DISK =~ s/p\d+$//;
				$DISKS{$DISK} = 1;
			} else {
				SDP::Core::printDebug("  singleDisk SKIP", $PART);
			}
			if ( scalar keys %DISKS > 1 ) {
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: singleDisk(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< singleDisk", "Returns: $RCODE");
	return $RCODE;
}

sub evmsNotActive {
	SDP::Core::printDebug('> evmsNotActive', 'BEGIN');
	my $RCODE = 1; # not active
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'evms.txt';
	my $SECTION = '/bin/ls -alR /dev/evms';
	my @CONTENT = ();
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^\s*$/ ) {
					$STATE = 0;
				} else {
					SDP::Core::printDebug("  evmsNotActive PROCESSING", $_);
					@LINE_CONTENT = split(/\s+/, $_);
					if ( $PARTITION{$LINE_CONTENT[$#LINE_CONTENT]} ) {
						$RCODE = 0; # found an active volume
						last;
					}
				}
			} elsif ( /\/dev\/evms\/.nodes:/ ) {
				$STATE = 1;
			} elsif ( /\/dev\/evms\/.nodes\/cciss:/ ) {
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: evmsNotActive(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< evmsNotActive", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $PACKAGE = 'novell-nss';
if ( SDP::SUSE::packageInstalled($PACKAGE) ) {
	if ( singleDisk() ) {
		if ( evmsNotActive() ) {
			my %SERVICE_INFO = SDP::SUSE::getServiceInfo($PACKAGE);
			if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Creating NSS Pools will result in an nssmu EVMS partition error 21705");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Creating NSS Pools may fail due to EVMS configuration for single system disk");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "EVMS Configured for NSS volumes on single system disk");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple disks found, skipping single disk NSS test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Novell NSS not installed, skipping single disk NSS test");
}
SDP::Core::printPatternResults();
exit;


