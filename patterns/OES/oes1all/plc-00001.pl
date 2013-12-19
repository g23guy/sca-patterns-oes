#!/usr/bin/perl

# Title:       Product Life Cycle: OES1 Linux
# Description: Open Enterprise Server (Linux) Supportability
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
	PROPERTY_NAME_CATEGORY."=Supportability",
	PROPERTY_NAME_COMPONENT."=Check",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_MISC",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_MISC = http://support.novell.com/lifecycle/",
	"META_LINK_CoolSolution = http://forums.novell.com/"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( $HOST_INFO{'oesmajor'} == 9 ) {
		my ($DAY, $MONTH, $YEAR) = (localtime)[3..5];
		my $DATE_TODAY = sprintf "%d%02d%02d", $YEAR+1900,$MONTH+1,$DAY;
		my $PRODUCT_STR = "Open Enterprise Server (Linux) OES1";
		my $END_GENERAL = 20090730;
		my $END_EXTENDED = 20110729;
		my $END_SELF = 20140730;
		if ( $DATE_TODAY > $END_SELF ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "$PRODUCT_STR is Not Supported");
		} elsif ( $DATE_TODAY > $END_EXTENDED ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Only Self-Support is offered for $PRODUCT_STR");
		} elsif ( $DATE_TODAY > $END_GENERAL ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Extended Support Contract Required for $PRODUCT_STR");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "$PRODUCT_STR is supported.");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES1 NOT installed, skipping PLC test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES NOT installed, skipping PLC test");
}
SDP::Core::printPatternResults();
exit;

