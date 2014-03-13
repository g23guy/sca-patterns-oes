#!/usr/bin/perl

# Title:       OES SLES Version Mismatch
# Description: OES is only supported on specific matching versions of SLES
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
	PROPERTY_NAME_CLASS."=Basic Health",
	PROPERTY_NAME_CATEGORY."=OES",
	PROPERTY_NAME_COMPONENT."=Versions",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005935",
	"META_LINK_Doc = http://www.novell.com/documentation/oes2/"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %MATCH_OES2_PATCH = ( # hash key = OES patch level, hash value = SLES patch level
	'3' => '3',
	'2' => '3',
	'1' => '2',
	'0' => '1',
);
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} != 9 ) {
	if ( $HOST_INFO{'oespatchlevel'} == 3 && $HOST_INFO{'patchlevel'} == 4 ) {
		SDP::Core::updateStatus(STATUS_SUCCESS, "Supported OES/SLES Versions Match");
	} elsif ( $MATCH_OES2_PATCH{$HOST_INFO{'oespatchlevel'}} == $HOST_INFO{'patchlevel'} ) {
		SDP::Core::updateStatus(STATUS_SUCCESS, "Supported OES/SLES Versions Match");
	} else {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Unsupported Version Pair: OES$HOST_INFO{'oesmajor'} SP$HOST_INFO{'oespatchlevel'} and SLES10 SP$HOST_INFO{'patchlevel'}");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Skipping version mismatch test, OES2 NOT Installed");
}
SDP::Core::printPatternResults();
exit;


