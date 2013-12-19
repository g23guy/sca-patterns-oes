#!/usr/bin/perl

# Title:       Novell NSS fails to load
# Description: The /tmp/nsslock file will prevent Novell NSS from loading
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
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006541"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub nsslockFound {
	SDP::Core::printDebug('> nsslockFound');
	my $RCODE = 0;
	my $FILE_OPEN = 'boot.txt';
	my $SECTION = 'boot.msg';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /nss.*Timed out waiting for NSS start up lock.*\/tmp\/nsslock/i ) {
				SDP::Core::printDebug("  nsslockFound PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nsslockFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( ! $RCODE ) {
		$FILE_OPEN = 'messages.txt';
		$SECTION = 'messages';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /nss.*Timed out waiting for NSS start up lock.*\/tmp\/nsslock/i ) {
					SDP::Core::printDebug("  nsslockFound PROCESSING", $_);
					$RCODE++;
					last;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nsslockFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	}
	SDP::Core::printDebug("< nsslockFound", "Returns: $RCODE");
	return $RCODE;
}

sub requiredServicesRunning {
	SDP::Core::printDebug('> requiredServicesRunning');
	my $RCODE = 0;
	my $SERVICE = 0;
	my $SERVICE_NAME = 'namcd';
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	$SERVICE++ if ( $SERVICE_INFO{'running'} > 0 );
	my @OUTPUT = ();
	if (SDP::Core::getSection("basic-health-check.txt", "/bin/ps axwwo", \@OUTPUT)) {
		foreach $_ (@OUTPUT) {
			if ( m/\/sbin\/ndsd/ ) {
				$SERVICE++;
				SDP::Core::printDebug('  requiredServicesRunning NDSD', $_);
				last;
			}
		}
		SDP::Core::printDebug('  requiredServicesRunning NDSD', "SERVICE = $SERVICE");
	}

	$RCODE = 1 if ( $SERVICE > 1 );
	SDP::Core::printDebug("< requiredServicesRunning", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $SERVICE = 'novell-nss';
if ( SDP::SUSE::packageInstalled($SERVICE) ) {
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE);
	if ( $SERVICE_INFO{'running'} > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Service $SERVICE_INFO{'name'} is running, /tmp/nsslock doesn't apply.");
	} else {
		if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) { # novell-nss is not running, but turned on
			if ( requiredServicesRunning() ) {
				if ( nsslockFound() ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "Remove /etc/nsslock and restart novell-nss");
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "No /etc/nsslock errors for novell-nss");
				}
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Required service(s) missing, skipping nsslock test");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Service $SERVICE_INFO{'name'} unused, /tmp/nsslock doesn't apply.");
		}
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing novell-nss package, skipping nsslock test");
}
SDP::Core::printPatternResults();
exit;

