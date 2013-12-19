#!/usr/bin/perl

# Title:       OES2 NSS NCP Cache too small
# Description: Files may not be listed properly if the number of files available to be cached is greater than the cache
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
use constant DEF_XCF_SUB => 4096; # OES2 MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY required
use constant DEF_XCF_VOL => 40000; # OES2 MAXIMUM_CACHED_FILES_PER_VOLUME required
use constant DEF_XCS_VOL => 100000; # OES2 MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME required
use constant INODE_THRESHOLD => 1500000;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=NCP",
	PROPERTY_NAME_COMPONENT."=Cache",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005345",
	"META_LINK_MISC = http://www.novell.com/support/php/search.do?cmd=displayKC&docType=kc&externalId=7004888"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getNCPcacheSettings {
	SDP::Core::printDebug('> getNCPcacheSettings', 'BEGIN');
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'novell-ncp.txt';
	my $SECTION = 'ncpserv.log';
	my @CONTENT = ();
	my %NCP = (
		MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY => 2048,
		MAXIMUM_CACHED_FILES_PER_VOLUME => 2000,
		MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME => 50000,
	);

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY has been set to (.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY'} );
			} elsif ( /MAXIMUM_CACHED_FILES_PER_VOLUME has been set to (.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_FILES_PER_VOLUME'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_FILES_PER_VOLUME'} );
			} elsif ( /MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME has been set to (.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME'} );
			}
		}
	}
	$SECTION = 'ncpserv.conf';
	@CONTENT = ();
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY\s+(.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY'} );
			} elsif ( /MAXIMUM_CACHED_FILES_PER_VOLUME\s+(.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_FILES_PER_VOLUME'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_FILES_PER_VOLUME'} );
			} elsif ( /MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME\s+(.*)/i ) {
				SDP::Core::printDebug("  getNCPcacheSettings PROCESSING", $_);
				$NCP{'MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME'} = $1 if ( $1 > $NCP{'MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME'} );
			}
		}
	}

	if ( $OPT_LOGLEVEL >= LOGLEVEL_DEBUG ) {
		my ($key, $value);
		print(' %NCP                           = ');
		while ( ($key, $value) = each(%NCP) ) {
			print("$key => \"$value\"  ");
		}
		print("\n");
	}

	SDP::Core::printDebug("< getNCPcacheSettings", "END");
	return %NCP;
}

sub validateNSSinodes {
	SDP::Core::printDebug('> validateNSSinodes', 'BEGIN');
	my $RCODE = 0;
	my $MAX_INODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'basic-health-check.txt';
	my $SECTION = 'df -i';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /\/media\/nss\// ) {
				SDP::Core::printDebug("  validateNSSinodes PROCESSING", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				$MAX_INODE = $LINE_CONTENT[2] if ( $MAX_INODE < $LINE_CONTENT[2] );
				if ( $LINE_CONTENT[2] >= INODE_THRESHOLD ) {
					$RCODE++;
					last;
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Client directory listings may fail due to NCP cache settings");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "NCP Cache Settings Appear Sufficent, Max Inodes Used: $MAX_INODE");
	}
	SDP::Core::printDebug("< validateNSSinodes", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	my %NCP = getNCPcacheSettings();
	if ( $NCP{'MAXIMUM_CACHED_FILES_PER_SUBDIRECTORY'} >= DEF_XCF_SUB && $NCP{'MAXIMUM_CACHED_FILES_PER_VOLUME'} >= DEF_XCF_VOL && $NCP{'MAXIMUM_CACHED_SUBDIRECTORIES_PER_VOLUME'} >= DEF_XCS_VOL ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Modified NCP Cache Settings Appear Sufficent");
	} else {
		validateNSSinodes();
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES Required for NCP Cache Test");
}
SDP::Core::printPatternResults();
exit;

