#!/usr/bin/perl

# Title:       NSS load error inserting nsscomn
# Description: novell-nss does not load properly due to misconfiguration
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
	PROPERTY_NAME_COMPONENT."=Configuration",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005577"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub moduleLoaded {
	SDP::Core::printDebug('> moduleLoaded', 'BEGIN');
	my $RCODE = 0;
	my $DRIVER_NAME = 'nsscomn';
	my %DRIVER_INFO = SDP::SUSE::getDriverInfo($DRIVER_NAME);
	$RCODE++ if ( $DRIVER_INFO{'loaded'} );
	SDP::Core::printDebug("< moduleLoaded", "Returns: $RCODE");
	return $RCODE;
}

sub errorFound {
	SDP::Core::printDebug('> errorFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'boot.txt';
	my $SECTION = 'boot.msg';
	my @CONTENT = ();
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^mknod: missing operand after `0'/ ) {
					SDP::Core::printDebug("  errorFound CONFIRMED", $_);
					$RCODE++;
					last;
				} elsif ( /^Starting/i ) {
					$STATE = 0;
				}
			} elsif ( /FATAL.*Error inserting nsscomn.*Operation not permitted/i ) {
				SDP::Core::printDebug("  errorFound PROCESSING", $_);
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: errorFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< errorFound", "Returns: $RCODE");
	return $RCODE;
}

sub invalidConfiguration {
	SDP::Core::printDebug('> invalidConfiguration', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-nss.txt';
	my $SECTION = 'nssstart.cfg';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^$|^#|^;/ ); # Skip blank or commented lines
			if ( ! /^\// ) {
				SDP::Core::printDebug("  invalidConfiguration CONFIRMED", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: invalidConfiguration(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< invalidConfiguration", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( invalidConfiguration() ) {
		if ( moduleLoaded() ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Modules loaded, but rebooting may cause novell-nss to fail, check nssstart.cfg");
		} else {
			my %SERVICE_INFO = SDP::SUSE::getServiceInfo('novell-nss');
			if ( $SERVICE_INFO{'runlevelstatus'} ) {
				if ( errorFound() ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "NSS Misconfiguration Causing Load Error");
				} else {
					SDP::Core::updateStatus(STATUS_WARNING, "Rebooting will cause novell-nss to fail, check nssstart.cfg");
				}
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Activating novell-nss and rebooting will fail to load, check nssstart.cfg");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No NSS misconfiguration observed in nssstart.cfg");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "OES NOT Installed on $HOST_INFO{'hostname'}");
}
SDP::Core::printPatternResults();
exit;

