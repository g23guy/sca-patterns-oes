#!/usr/bin/perl

# Title:       iPrint Plugin Needed
# Description: Suggest the iPrint plugin as needed
# Modified:    2013 Jun 25
my $VERSION_TO_COMPARE = '1.0-3';

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
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=Plugin",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_OBS=http://software.opensuse.org/search?baseproject=SUSE%3ASLE-10&p=1&q=supportutils-plugin-iprint",
	"META_LINK_Patch=http://download.opensuse.org/repositories/Novell:/NTS/SLE_10/noarch/supportutils-plugin-iprint-1.0-3.1.noarch.rpm"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( packageInstalled('novell-iprint-server') ) {
		my $RPM_NAME = 'supportutils-plugin-iprint';
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
		if ( $RPM_COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Install Supportconfig Plugin for iPrint and run iPrintInfo");
		} elsif ( $RPM_COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
		} else {
			if ( $RPM_COMPARISON < 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Update the Supportconfig Plugin for iPrint for better results");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "The current $RPM_NAME is installed");
			}			
		}

	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "iPrint not installed, skipping plugin warning");
	}
SDP::Core::printPatternResults();

exit;


