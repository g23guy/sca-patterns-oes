#!/usr/bin/perl

# Title:       novell-afptcpd fails to load on 32bit OES2SP2
# Description: Checks novell-afptcpd and avahi-daemon interaction
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
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

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
	PROPERTY_NAME_CATEGORY."=AFP",
	PROPERTY_NAME_COMPONENT."=Daemon",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005351",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=574328"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'architecture'} =~ /i?86/i ) {
	my @AFP = SDP::SUSE::getRpmInfo('novell-afptcpd');
	my @AVA = SDP::SUSE::getRpmInfo('avahi');
	if ( $#AFP == 0 && $#AVA == 0 ) { # both packages are installed
		my %AFP_SERVICE = SDP::SUSE::getServiceInfo('novell-afptcpd');
		my %AVA_SERVICE = SDP::SUSE::getServiceInfo('avahi-daemon');
		if ( $AVA_SERVICE{'running'} ) {
			if ( $AFP_SERVICE{'runlevelstatus'} && $AFP_SERVICE{'running'} == 0 ) { # turned on but not running
				SDP::Core::updateStatus(STATUS_CRITICAL, "Service novell-afptcpd conflicts with avahi-daemon");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "No avahi-daemon conflict observed, service novell-afptcpd running") if ( $AFP_SERVICE{'running'} );
				SDP::Core::updateStatus(STATUS_ERROR, "No avahi-daemon conflict observed, service novell-afptcpd turned off") if ( ! $AFP_SERVICE{'runlevelstatus'} );
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Service avahi-daemon does not conflict with novell-afptcpd");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: novell-afptcpd and avahi-daemon needed for interaction test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES 32bit required for AFP check");
}
SDP::Core::printPatternResults();
exit;

