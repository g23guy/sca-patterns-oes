#!/usr/bin/perl

# Title:       Shadow volume files as Primary directories
# Description: Files initially only residing on the shadow volume can end up as directories on the Primary volume
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=DST",
	PROPERTY_NAME_COMPONENT."=Volumes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008532",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=689922"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::OESLinux::shadowVolumes() ) {
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oesmajor'} == 2 ) {
		my $RPM_NAME = 'novell-ncpenc';
		my $VERSION_TO_COMPARE = 0;
		if ( $HOST_INFO{'oespatchlevel'} == 3 ) {
			$VERSION_TO_COMPARE = '5.1.5-0.39';
		} elsif  ( $HOST_INFO{'oespatchlevel'} == 2 ) {
			$VERSION_TO_COMPARE = '5.1.4-0.11.22';
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2 SP3 or SP2 required, skipping DST test");
		}
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
		if ( $RPM_COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
		} elsif ( $RPM_COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
		} else {
			if ( $RPM_COMPARISON <= 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Shadow volume files may move to Primary volume directories");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Shadow volume files should NOT move to Primary volume directories");
			}			
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES version 2 required, skipping DST test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: DST Volumes required, skipping test");
}
SDP::Core::printPatternResults();
exit;

