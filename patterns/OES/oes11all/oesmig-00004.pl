#!/usr/bin/perl

# Title:       OES2 Linux target should have namcd loaded/healthy
# Description: Migration authentication will fail if namcd is not loaded or in a dead or defunct state.
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
	PROPERTY_NAME_CATEGORY."=Migration",
	PROPERTY_NAME_COMPONENT."=Volumes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001767"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $FILE_NAME = 'novell-lum.txt';
my $SERVICE_NAME = 'namcd';
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} == 2 ) {
	my $SERVICE_STATUS = SDP::SUSE::serviceStatus($FILE_NAME, $SERVICE_NAME);
	if ( $SERVICE_STATUS == 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "OES2 Migration Check, Service is Running: $SERVICE_NAME");
	} else {
		SDP::Core::updateStatus(STATUS_CRITICAL, "OES2 Migration Check, Service is NOT Running: $SERVICE_NAME");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, 'Outside scope, OES2 Not installed');
}
SDP::Core::printPatternResults();
exit;


