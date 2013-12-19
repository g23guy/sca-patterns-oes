#!/usr/bin/perl

# Title:       Unable to open files through NCP
# Description: Cannot open files after oes2sp3-April-2011-Scheduled-Maintenance
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
	PROPERTY_NAME_COMPONENT."=Files",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008349",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=686630"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( $HOST_INFO{'oesmajor'} == 2 && $HOST_INFO{'oespatchlevel'} == 3  ) {
		my $RPM_NAME = 'novell-ncpenc';
		my $VERSION_TO_COMPARE = '5.1.5-0.36';
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
		if ( $RPM_COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
		} elsif ( $RPM_COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
		} else {
			if ( $RPM_COMPARISON == 0 ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Files may fail to open on NCP volumes, update server for fix.");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "NCP volume files should open properly, punting");
			}			
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2 SP3 required, skipping NCP engine test.");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES required, skipping NCP engine test.");
}
SDP::Core::printPatternResults();
exit;

