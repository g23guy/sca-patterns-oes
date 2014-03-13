#!/usr/bin/perl

# Title:       Master TID: Novell iPrint
# Description: List of common Novell iPrint issues
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
	PROPERTY_NAME_CATEGORY."=Master TID",
	PROPERTY_NAME_COMPONENT."=iPrint",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_Master",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_Master=http://www.suse.com/support/kb/doc.php?id=7007025"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $PKG_NAME = 'novell-iprint-server';
	if ( SDP::SUSE::packageInstalled($PKG_NAME) ) {
		SDP::Core::updateStatus(STATUS_RECOMMEND, "Consider TID7007025 - iPrint for Linux Master TID, FAQ and Common Issues");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Master TID not applicable, missing: $PKG_NAME");
	}
SDP::Core::printPatternResults();

exit;


