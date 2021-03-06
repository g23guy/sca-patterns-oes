#!/usr/bin/perl

# Title:       Tomcat issue with iManager
# Description: Restarting tomcat causes the contents of /var/opt/novell/iManager to be deleted
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
	PROPERTY_NAME_CATEGORY."=iManager",
	PROPERTY_NAME_COMPONENT."=Directory",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005833",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=596759"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	my $RPM_NAME = 'tomcat5';
	my $VERSION_TO_COMPARE = '5.0.30-27.42';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		if ( $RPM_COMPARISON == 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Possible Tomcat issue, files in /var/opt/novell/iManager may get deleted");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Tomcat file delete issue not observed");
		}			
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES Required for Tomcat test");
}
SDP::Core::printPatternResults();
exit;

