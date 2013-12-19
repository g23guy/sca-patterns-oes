#!/usr/bin/perl

# Title:       Miggui will fail to authenticate if required path entries are missing
# Description: Miggui requires these entries in the current path for proper authentication to the target server: /opt/novell/eDirectory/sbin:/opt/novell/eDirectory/bin:/opt/novell/migration/sbin
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
	PROPERTY_NAME_COMPONENT."=Paths",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002862"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkPathVar {
	SDP::Core::printDebug('> checkPathVar', 'BEGIN');
	my $RCODE;
	my $FILE_OPEN = 'env.txt';
	my $SECTION = '/usr/bin/env';
	my @REQUIRED_PATHS = qw(/opt/novell/eDirectory/sbin /opt/novell/eDirectory/bin /opt/novell/migration/sbin);
	my @MISSING_PATHS = ();
	my @CONTENT = ();
	my $I;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ );                  # Skip blank lines
			if ( /^PATH=/ ) {
				SDP::Core::printDebug("  checkPathVar TAKE ACTION ON", $_);
				foreach $I (@REQUIRED_PATHS) {
					if ( /$I/ ) {
						SDP::Core::printDebug(" checkPathVar SEARCH", $I . " - Found");
					} else {
						SDP::Core::printDebug(" checkPathVar SEARCH", $I . " - MISSING");
						push(@MISSING_PATHS, $I);
					}
				}
				last;
			}
		}
		if ( $#MISSING_PATHS >= 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "OES2 Migration Check, Invalid miggui PATH in root's environment, missing: @MISSING_PATHS");
			$RCODE = 1;
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Migration Check, Valid miggui PATH in root's environment");
			$RCODE = 0;
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkPathVar", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} > 1 ) {
	checkPathVar();
} else {
	SDP::Core::updateStatus(STATUS_ERROR, 'Outside scope, OES2 Not installed');
}
SDP::Core::printPatternResults();
exit;


