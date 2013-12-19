#!/usr/bin/perl

# Title:       Check afptcp configuration induced high utilization
# Description: OES2 SP2 afptcp causes high utilization when accessing files from a MAC
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

use constant MIN_THREADS_DEFAULT => 3;
use constant MAX_THREADS_DEFAULT => 32;
use constant AFP_CRITICAL_THRESHOLD => 15;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=AFP",
	PROPERTY_NAME_COMPONENT."=Performance",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006489"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub afptcpdPercent {
	SDP::Core::printDebug('> afptcpdPercent', 'BEGIN');
	my $RCODE = -1; # assume the service is not running
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'basic-health-check.txt';
	my $SECTION = 'ps axwwo';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /bin\/afptcpd/ ) {
				SDP::Core::printDebug("  afptcpdPercent PROCESSING", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				$RCODE = $LINE_CONTENT[3];
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: afptcpdPercent(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< afptcpdPercent", "Returns: $RCODE");
	return $RCODE;
}

sub nonDefaultThreads {
	SDP::Core::printDebug('> nonDefaultThreads', 'BEGIN');
	my $RCODE = 0;
	my $FLAG = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'novell-afp.txt';
	my $SECTION = '/afptcpd.conf';
	my @CONTENT = ();
	my $MIN_THREADS = 0;
	my $MAX_THREADS = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^MIN_THREADS\s+(.*)/ ) {
				SDP::Core::printDebug("  nonDefaultThreads PROCESSING", $_);
				$MIN_THREADS = $1;
				$FLAG++;
			} elsif ( /^MAX_THREADS\s+(.*)/ ) {
				SDP::Core::printDebug("  nonDefaultThreads PROCESSING", $_);
				$MAX_THREADS = $1;
				$FLAG++;
			}
			last if ( $FLAG > 1 );
		}
		if ( $MIN_THREADS > MIN_THREADS_DEFAULT ) {
			$RCODE++;
		}
		if ( $MAX_THREADS > MAX_THREADS_DEFAULT ) {
			$RCODE++;
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nonDefaultThreads(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< nonDefaultThreads", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oesmajor'} > 1 ) {
	my $PKG_NAME = 'novell-afptcpd';
	if ( SDP::SUSE::packageInstalled($PKG_NAME) ) {
		my $AFP_PERCENT = afptcpdPercent();
		if ( $AFP_PERCENT == -1 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "Novell AFP not running, skipping AFP thread test");
		} else {
			if ( nonDefaultThreads() ) {
				if ( $AFP_PERCENT > AFP_CRITICAL_THRESHOLD ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "MIN/MAX_THREADS causing high afptcpd utilization from MAC client access");
				} else {
					SDP::Core::updateStatus(STATUS_WARNING, "MIN/MAX_THREADS may result in high afptcpd utilization from MAC client access");
				}
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "MIN/MAX_THREADS are not affecting AFP utilization from MAC client access");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Novell AFP Services not installed on $HOST_INFO{'hostname'}, skipping AFP thread test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "OES NOT Installed on $HOST_INFO{'hostname'}, skipping AFP thread test");
}
SDP::Core::printPatternResults();
exit;

