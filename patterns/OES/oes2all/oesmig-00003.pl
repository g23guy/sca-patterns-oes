#!/usr/bin/perl

# Title:       OES2 Linux target smdrd should be listening on port 40193
# Description: Smdrd has not loaded correctly if the server is not listening for communication on port 40193.
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
	PROPERTY_NAME_CATEGORY."=Migration",
	PROPERTY_NAME_COMPONENT."=Ports",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002862"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $PORT_NUM = '40193';
my $PORT_EXPECT = 'smdrd';
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} > 1 ) {
	my %PORT_INFO = SDP::SUSE::portInfo($PORT_NUM);
	if ( %PORT_INFO ) {
		if ( $PORT_INFO{'service'} =~ /$PORT_EXPECT/i ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Migration Check, Port Listening: $PORT_INFO{'service'} listening on $PORT_NUM");
		} else {
			SDP::Core::updateStatus(STATUS_CRITICAL, "OES2 Migration Check, Port Conflict: $PORT_INFO{'service'} on $PORT_NUM, Expecting $PORT_EXPECT");
		}
	} else {
		SDP::Core::updateStatus(STATUS_CRITICAL, "OES2 Migration Check, Port NOT Listening: $PORT_NUM");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, 'Outside scope, OES2 Not installed');
}
SDP::Core::printPatternResults();
exit;


