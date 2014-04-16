#!/usr/bin/perl -w

# Title:       migfiles and Server Consolidation Migration fails migration
# Description: migfiles Error: An internal error has occurred. One or more of the parameters is null or invalid.
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
#     Jason Record (jrecord@suse.com)
#
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
	PROPERTY_NAME_COMPONENT."=Parameters",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3642855",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=366569"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $MIGRPM_NAME = "glibc-locale-32bit";
my $MIGRPM_VER = "2.4-31.43.6";
my $MIGRPM = $MIGRPM_NAME . "-" . $MIGRPM_VER;

# OES2 must be installed
# must be a 64bit x86_64 architecture
# RPM glibc-locale-32bit-2.4-31.43.6 is missing or an earlier version is installed
#  "rcnovell-smdrd restart", maybe add to the green status

my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'architecture'} =~ /x86_64/i ) {
	SDP::Core::updateStatus(STATUS_ERROR, "OES on 64bit architecure detected");
	my $RPMCMP = compareRpm('glibc-locale-32bit', '2.4-31.43.6');
	if      ( $RPMCMP == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "RPM Not Installed: $MIGRPM");
	} elsif ( $RPMCMP == 3 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Multiple RPM Versions: $MIGRPM_NAME");
	} elsif ( $RPMCMP < 0 ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Updated RPM needed: $MIGRPM_NAME");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "RPM Version is correct: $MIGRPM_NAME");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ABORT: OES on 64bit architecure not found");
}	
SDP::Core::printPatternResults();
exit;

