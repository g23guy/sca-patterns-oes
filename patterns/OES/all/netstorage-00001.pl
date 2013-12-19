#!/usr/bin/perl

# Title:       Error Accessing NetStorage after OES NSS install
# Description: Error 500 accessing NetStorage after NSS install on OES linux resulting in Connection creation failed
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
	PROPERTY_NAME_CATEGORY."=NetStorage",
	PROPERTY_NAME_COMPONENT."=Connections",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3595588"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkHttpErrors {
	SDP::Core::printDebug('> checkHttpErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $LINE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ );                  # Skip blank lines
			if ( /httpd2-worker.*XSrvCChannel::connectSocket.*Connection creation failed.*error\s+=\s+13/i ) { # Look for this first
				SDP::Core::printDebug("  checkHttpErrors LINE $LINE", $_);
				$RCODE = 1;
			} elsif ( $RCODE ) { # look for the xtier path if the connection creation failed message was received above
				if ( /httpd2-worker.*Channel Initialization failed for socket \/var\/opt\/novell\/xtier\/xsrvd/i ) {
					SDP::Core::printDebug("  checkHttpErrors LINE $LINE", $_);
					$RCODE = 2;
					last;
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE > 1 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Possible incorrect xtier UID for NetStorage");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No Error 13 messages found for NetStorage and NSS integration");
	}
	SDP::Core::printDebug("< checkHttpErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::SUSE::packageInstalled('novell-netstorage') && SDP::SUSE::packageInstalled('novell-nss') ) {
	checkHttpErrors();
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Missing one or more RPM Packages: novell-netstorage, novell-nss");
}
SDP::Core::printPatternResults();
exit;

