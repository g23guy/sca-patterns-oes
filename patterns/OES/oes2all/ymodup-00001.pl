#!/usr/bin/perl

# Title:       The YaST channel-upgrade-oes module fails
# Description: After installing the move-to-oes2-sp2, the channel-upgrade-oes module may fail
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
	PROPERTY_NAME_CATEGORY."=Upgrade",
	PROPERTY_NAME_COMPONENT."=YaST",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005424"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub analyzeModuleError {
	SDP::Core::printDebug('> analyzeModuleError', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'y2log.txt';
	my $SECTION = '/var/log/YaST2/y2log';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /channel-upgrade-oes.ycp:44 Can\'t load module.*NovellCifs/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			} elsif ( /channel-upgrade-oes.ycp:43 Can\'t load module.*NovellAfp/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			} 
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "YaST channel-upgrade-oes module failure, missing dependency: yast2-novell-afp or yast2-novell-cifs");
	} else {
		SDP::Core::updateStatus(STATUS_WARNING, "YaST channel-upgrade-oes module missing dependency: yast2-novell-afp or yast2-novell-cifs");
	}
	SDP::Core::printDebug("< analyzeModuleError", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $RPM_NAME = 'yast2-novell-common';
my $VERSION_TO_COMPARE = '2.13.8-121'; # yast2-novell-common package version that ships with OES2 SP2
my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
if ( $RPM_COMPARISON >= 2 ) {
	SDP::Core::updateStatus(STATUS_ERROR, "ABORT: Package $RPM_NAME not installed, skipping channel-upgrade-oes test");
} else {
	if ( $RPM_COMPARISON >= 0 ) {
		if ( SDP::SUSE::packageInstalled('yast2-novell-afp') && SDP::SUSE::packageInstalled('yast2-novell-cifs') ) {
			SDP::Core::updateStatus(STATUS_ERROR, "YaST channel-upgrade-oes module error not observed");
		} else {
			analyzeModuleError();
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ABORT: Package $RPM_NAME is outdated, skipping channel-upgrade-oes test");
	}
}
SDP::Core::printPatternResults();
exit;

