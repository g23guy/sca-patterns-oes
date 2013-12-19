#!/usr/bin/perl

# Title:       Failure to add domain controller to DSfW
# Description: Unable to add additional Domain Controller to DSfW domain when the domain name ends with .local
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=DSfW",
	PROPERTY_NAME_COMPONENT."=Controller",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006468",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=619153",
	"META_LINK_WEB=http://www.multicastdns.org/"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub localDomainEdir {
	SDP::Core::printDebug('> localDomainEdir', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-edir.txt';
	my $SECTION = 'nds.conf'; # this will look at the first nds.conf section it finds, does not support multiple eDir conf files.
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /n4u.xad.dns-domain=.*\.local$/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: localDomainEdir(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< localDomainEdir", "Returns: $RCODE");
	return $RCODE;
}

sub mdnsOff {
	SDP::Core::printDebug('> mdnsOff', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'network.txt';
	my $SECTION = '/etc/hosts';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /mdns.*off/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: mdnsOff(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< mdnsOff", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::OESLinux::dsfwCapable() ) {
		if ( localDomainEdir() ) {
			if ( mdnsOff() ) {
				SDP::Core::updateStatus(STATUS_ERROR, "The mdns off should allow additional DSfW domain controllers");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "If unable to add additional domain controller to DSfW, consider mdns off");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: No eDirectory .local domain defined for DSfW test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR, Server is not DSfW capable");
	}
SDP::Core::printPatternResults();

exit;

