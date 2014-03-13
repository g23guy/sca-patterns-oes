#!/usr/bin/perl

# Title:       Viewing Dynamic DHCP Leases in the Management Console
# Description: OES2SP3 Configuration instructions for viewing DHCP leases through the DNS/DHCP Management Console.
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
	PROPERTY_NAME_CATEGORY."=DHCP",
	PROPERTY_NAME_COMPONENT."=System",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006450"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oes'} ) {
		if ( $HOST_INFO{'oesmajor'} >= 2 && $HOST_INFO{'oespatchlevel'} >= 3  ) {
			my $SERVICE_NAME = 'dhcpd';
			my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
			if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
				SDP::Core::updateStatus(STATUS_RECOMMEND, "Viewing Dynamic DHCP Leases in the Management Console");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "DHCP Not in Use, Skipping DHCP Recommendation");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2SP3 or Higher Required, Skipping DHCP Recommendation");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "OES Required, Skipping DHCP Recommendation");
	}
SDP::Core::printPatternResults();

exit;

