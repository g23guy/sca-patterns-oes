#!/usr/bin/perl

# Title:       Linux iprint user and/or group does not exist
# Description: The iprint user and group are required
# Modified:    2013 Jun 25

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
	PROPERTY_NAME_COMPONENT."=User",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003592"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub missingUser {
	SDP::Core::printDebug('> missingUser', 'BEGIN');
	my $RCODE = 1; #Assume missing iprint user
	my $FILE_OPEN = 'pam.txt';
	my $SECTION = 'getent passwd';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^iprint:/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingUser(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< missingUser", "Returns: $RCODE");
	return $RCODE;
}

sub missingGroup {
	SDP::Core::printDebug('> missingGroup', 'BEGIN');
	my $RCODE = 1; #Assume missing iprint user
	my $FILE_OPEN = 'pam.txt';
	my $SECTION = 'getent group';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^iprint:/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingGroup(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< missingGroup", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::packageInstalled('novell-iprint-server') ) {
		if ( missingUser() ) {
			if ( missingGroup() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Missing iprint user and group, required for iPrint Driver Store and Print Manager");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Missing iprint user, required for iPrint Driver Store and Print Manager");
			}
		} else {
			if ( missingGroup() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Missing iprint group, required for iPrint Driver Store and Print Manager");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Found iprint user and group");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "iPrint not installed, skipping user/group test");
	}
SDP::Core::printPatternResults();

exit;

