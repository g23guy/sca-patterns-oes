#!/usr/bin/perl

# Title:       Trustees missing after applying NCP Server update
# Description: The ncp2nss service needs to be running to use trustees
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
	PROPERTY_NAME_CATEGORY."=NCP",
	PROPERTY_NAME_COMPONENT."=Trustees",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3686305",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=191815"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::SUSE::packageInstalled('novell-ncpserv') ) {
	my $SERVICE_NAME = 'ncp2nss';
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	if ( $SERVICE_INFO{'running'} > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "NCP Server causing missing trustees avoided, $SERVICE_INFO{'name'} is running");
	} else {
		if ( $SERVICE_INFO{'runlevelstatus'} ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "NCP Server contributing to missing trustees, reload $SERVICE_INFO{'name'}");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: An activated OES NCP Server required");
		}
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES NCP Server required");
}
SDP::Core::printPatternResults();
exit;

