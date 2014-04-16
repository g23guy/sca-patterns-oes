#!/usr/bin/perl

# Title:       Invalid CIMOM client credentials
# Description: rcowcimomd fails to start and logs errors
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
	PROPERTY_NAME_CATEGORY."=CIMON",
	PROPERTY_NAME_COMPONENT."=Port",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007187"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $SERVICE_NAME = 'owcimomd';
my $PORT_NUMBER = '5989';
my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
	my %PORT_INFO = SDP::SUSE::portInfo($PORT_NUMBER);
	if ( %PORT_INFO ) {
		if ( $PORT_INFO{'service'} =~ m/$SERVICE_NAME/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "No port conflict: $PORT_INFO{'service'} is listening on port $PORT_NUMBER");
		} else {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Port conflict: $PORT_INFO{'service'} running on $PORT_NUMBER, conflicts with $SERVICE_NAME");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Nothing listening on port $PORT_NUMBER");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Service $SERVICE_NAME is turned off, skipping port test");
}
SDP::Core::printPatternResults();
exit;

