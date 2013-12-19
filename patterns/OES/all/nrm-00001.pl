#!/usr/bin/perl

# Title:       Novell Remote Manager Will Not Load
# Description: Novell Remote Manager or NRM will not load.
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
	PROPERTY_NAME_CATEGORY."=NRM",
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007098"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub pidFound {
	SDP::Core::printDebug('> pidFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'basic-health-check.txt';
	my $SECTION = '/bin/ps ';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /\/httpstkd/ ) {
				SDP::Core::printDebug("  pidFound PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: pidFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< pidFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $SERVICE_NAME = 'novell-httpstkd';
my $REQUIRED_VERSION = '2.25-252';
my %SC_INFO = SDP::SUSE::getSCInfo();
if ( SDP::Core::compareVersions($SC_INFO{'version'}, $REQUIRED_VERSION) >= 0 ) {
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
		if ( $SERVICE_INFO{'running'} < 1 ) {
			if ( pidFound() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Remote Manager Page Will Fail to Load, Clear and Restart $SERVICE_NAME");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Remote Manager Page Will Fail to Load, Restart $SERVICE_NAME");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "IGNORE: Service $SERVICE_INFO{'name'} is running, skipping dead service test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "IGNORE: Service $SERVICE_INFO{'name'} Not Enabled, skipping dead service test");
	}
} else {
	my $PACKAGE = 'novell-nrm';
	if ( SDP::SUSE::packageInstalled($PACKAGE) ) {
		SDP::Core::updateStatus(STATUS_RECOMMEND, "ERROR: Supportconfig v$REQUIRED_VERSION or higher needed to check Novell Remote Manager");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Novell Remote Manager not installed, skipping test");
	}
}
SDP::Core::printPatternResults();
exit;

