#!/usr/bin/perl

# Title:       OES2SP2 migfiles/miggui does not work
# Description: migfiles/miggui failing with ruby errors
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
	PROPERTY_NAME_COMPONENT."=Tools",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004949",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=559555"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} ) {
	if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'}, '2.0.2') == 0 ) {
		my $RPM_NAME = 'ruby';
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, '1.8.6.p369-0.5');
		if ( $RPM_COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
		} elsif ( $RPM_COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
		} else {
			if ( $RPM_COMPARISON == 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Invalid ruby version for migfiles and miggui");
			} else {
				my $RUBY_COMPARE = SDP::SUSE::compareRpm($RPM_NAME, '1.8.4-17.20');
				if ( $RUBY_COMPARE == 0 ) {
					SDP::Core::updateStatus(STATUS_ERROR, "Valid ruby version for Migration Tools observed");
				} else {
					SDP::Core::updateStatus(STATUS_WARNING, "Confirm ruby version in rpm.txt for migfiles and miggui");
				}
			}                       
		}		
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: migfiles ruby check for 2.0.2 only, found version $HOST_INFO{'oesversion'}.");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: migfiles ruby check for OES only.");
}
SDP::Core::printPatternResults();
exit;

