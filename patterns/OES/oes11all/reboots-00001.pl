#!/usr/bin/perl

# Title:       Cluster nodes rebooting randomly
# Description: After applying the March 2010 updates Novell Cluster Services nodes reboot randomly.
# Modified:    2013 Jun 21

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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Node",
	PROPERTY_NAME_COMPONENT."=Reboot",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005916",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=601179"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub knownKernels {
	SDP::Core::printDebug('> knownKernels', 'BEGIN');
	my $RCODE = 0;
	if ( SDP::SUSE::compareKernel('2.6.16.60-0.60.1') == 0 || SDP::SUSE::compareKernel('2.6.16.60-0.42.9') == 0 || SDP::SUSE::compareKernel('2.6.16.60-0.42.8') == 0 ) {
		$RCODE++;
	}
	SDP::Core::printDebug("< knownKernels", "Returns: $RCODE");
	return $RCODE;
}

sub cpuCount {
	SDP::Core::printDebug('> cpuCount', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'hardware.txt';
	my $SECTION = '/proc/cpuinfo';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /processor\s+:./ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: cpuCount(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< cpuCount", "Returns: $RCODE");
	return $RCODE;
}

sub clusteringRunning {
	SDP::Core::printDebug('> clusteringRunning', 'BEGIN');
	my $RCODE = 0;
	my $SERVICE_NAME = 'novell-ncs';
	my $OES2 = 0;
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	$OES2 = 1 if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'}, '2.0.0') >= 0 );
	$RCODE++ if ( $SERVICE_INFO{'running'} && $OES2 );

	$SERVICE_NAME = 'heartbeat';
	%SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	%HOST_INFO = SDP::SUSE::getHostInfo();
	$RCODE++ if ( $SERVICE_INFO{'running'} );

	$SERVICE_NAME = 'openais';
	%SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	%HOST_INFO = SDP::SUSE::getHostInfo();
	$RCODE++ if ( $SERVICE_INFO{'running'} );

	SDP::Core::printDebug("< clusteringRunning", "Returns: $RCODE");
	return $RCODE;
}

sub knownHardware {
	SDP::Core::printDebug('> knownHardware', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $HARDWARE = '';
	my $CHECK = '';
	my $FILE_OPEN = 'hardware.txt';
	my $SECTION = 'hwinfo';
	my @CONTENT = ();
	my @CONFIRMED_LIST = ('PowerEdge 2950', 'PowerEdge 1950', 'ProLiant DL380 G5', 'ProLiant DL380 G6', 'BL460c G1');

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /smbios.system.product/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				@LINE_CONTENT = split(/=/, $_);
				$LINE_CONTENT[1] =~ s/\'|\"//g; # remove quotes
				$LINE_CONTENT[1] =~ s/^\s+|\s+$//g; # remove leading/trailing white space
				$HARDWARE = $LINE_CONTENT[1];
				last;
			}
		}
	} else { # search dmidecode if supportconfig -k used
		$SECTION = 'dmidecode';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			my $STATE = 0;
			foreach $_ (@CONTENT) {
				next if ( /^\s*$/ ); # Skip blank lines
				if ( $STATE ) {
					SDP::Core::printDebug("PROCESSING", $_);
					if ( /^\S/ ) {
						last;
					} elsif ( /Product Name:\s+.*/ ) {
						@LINE_CONTENT = split(/:/, $_);
						$LINE_CONTENT[1] =~ s/\'|\"//g; # remove quotes
						$LINE_CONTENT[1] =~ s/^\s+|\s+$//g; # remove leading/trailing white space
						$HARDWARE = $LINE_CONTENT[1];
						last;
					}
				} elsif ( /System Information/i ) {
					SDP::Core::printDebug("PROCESSING STATE", $_);
					$STATE = 1;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: knownHardware(): Cannot find hwinfo or dmidecode sections in $FILE_OPEN");
		}
	}
	if ( $HARDWARE ) {
		foreach $CHECK (@CONFIRMED_LIST) {
			SDP::Core::printDebug("CHECKING", $CHECK);
			if ( $HARDWARE =~ m/$CHECK/i ) {
				SDP::Core::printDebug(" CONFIRMED", $HARDWARE);
				$RCODE++;
				last;
			} else {
				SDP::Core::printDebug(" DENIED", $HARDWARE);
			}
		}
	}
	SDP::Core::printDebug("< knownHardware", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( knownKernels() ) {
		if ( cpuCount() >= 4 ) {
			if ( clusteringRunning() ) {
				if ( knownHardware() ) {
					SDP::Core::updateStatus(STATUS_WARNING, "Cluster node susceptible to random reboots");
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "Cluster node not susceptible to specific random reboots");
				}
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Running cluster required, skipping random reboot test");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Insufficient CPU count, skipping random reboot test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Outside kernel scope, skipping random reboot test");
	}
SDP::Core::printPatternResults();

exit;

