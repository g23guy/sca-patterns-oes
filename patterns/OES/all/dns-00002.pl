#!/usr/bin/perl

# Title:       Check for Missing DNS Locator Object
# Description: The DNS Locator object is required for Novell NDS
# Modified:    2013 Jun 24

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
	PROPERTY_NAME_CATEGORY."=DNS",
	PROPERTY_NAME_COMPONENT."=Locator",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005339"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub missingDnsLocator {
	SDP::Core::printDebug('> missingDnsLocator', 'BEGIN');
	my $RCODE = 1; # Assume locator object is missing
	my $OBJECTS = 0;
	my $FILE_OPEN = 'dns.txt';
	my $SECTION = 'objectclass=dNIPLocator';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^$|^#/ ); # Skip blank or comment lines
			if ( /^objectClass:\sdNIPLocator/ ) {
				$OBJECTS++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $OBJECTS == 1) {
		$RCODE = 0;
	}
	SDP::Core::printDebug("< missingDnsLocator", "Returns: $RCODE");
	return $RCODE;
}

sub dnsRunning {
	SDP::Core::printDebug('> dnsRunning', 'BEGIN');
	my $RCODE = 0;
	my $SRC_FILE = 'dns.txt';
	my $SERVICE_NAME = 'novell-named';
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SRC_FILE, $SERVICE_NAME);
	if ( $SERVICE_INFO{'running'} ) {
		$RCODE = 1;
	}
	SDP::Core::printDebug("< dnsRunning", "Returns: $RCODE");
	return $RCODE;
}

sub foundLookupErrors {
	SDP::Core::printDebug('> foundLookupErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'dns.txt';
	my $SECTION = 'named.run';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			if ( /critical.*Unable to read locator reference from NCP server/i ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< foundLookupErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( missingDnsLocator() ) {
		if ( dnsRunning() ) {
			if ( foundLookupErrors() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Missing DNS Locator Object, DNS Running, But Lookup Errors Found");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Missing DNS Locator Object, Resolve Before Rebooting");
			}
		} else {
			if ( foundLookupErrors() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Missing DNS Locator Object, Lookup Errors Found");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Missing DNS Locator Object, DNS Not Running");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "DNS Locator Object Found in Context");
	}
SDP::Core::printPatternResults();

exit;

