#!/usr/bin/perl

# Title:       Detect Corrupted Resource Priority List
# Description: Checks for a possible corrupted NCS resource priority list
# Modified:    2013 Jun 21

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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Priority",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001365",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=159290"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getResourceList {
	#SDP::Core::printDebug('> getResourceList', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'ncsldapCheck.py';
	my @CONTENT = ();
	my @PY_RESOURCES = ();
	my $STATE = 0;
	my $RESOURCE = '';

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^\stype: (.*)/ ) {
					if ( $1 !~ m/nCSResourceTemplate/ ) {
						#SDP::Core::printDebug(" PUSH", $RESOURCE);
						push(@PY_RESOURCES, $RESOURCE);
					} else {
						##SDP::Core::printDebug(" DROP", $RESOURCE);
					}
				} elsif ( /^\srevision:/ ) {
					$STATE = 0;
				}
			} elsif ( /Resource\/template name: (.*)/ ) {
				#SDP::Core::printDebug("PROCESSING", $_);
				$RESOURCE = $1;
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getResourceList(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	#SDP::Core::printDebug("CHECK", "Resources: @PY_RESOURCES");
	$RCODE = scalar @PY_RESOURCES;
	#SDP::Core::printDebug("< getResourceList", "Valid Resources: $RCODE");
	return @PY_RESOURCES;
}

sub checkResourceList {
	my @VALID_RESOURCES = @_;
	#SDP::Core::printDebug('> checkResourceList', "@VALID_RESOURCES");
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'cluster resources';
	my @CONTENT = ();
	my @MISSING_RESOURCES = ();
	my ($VALID, $FOUND) = (0,0);
	my $MEMBER_NODE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			#SDP::Core::printDebug("NODE CHECK", $_);
			if ( /^Name.*State.*Node.*Lives/i ) {
				$MEMBER_NODE = 1;
				last;
			}
		}
		if ( $MEMBER_NODE ) {
			foreach $VALID (@VALID_RESOURCES) {
				#SDP::Core::printDebug("VALIDATING", "$VALID");
				my $MISSING = 1;
				foreach $FOUND (@CONTENT) {
					next if ( $FOUND =~ m/^\s*$/ ); # Skip blank lines
					if ( $FOUND =~ m/^$VALID/ ) {
						#SDP::Core::printDebug(" Confirmed", $FOUND);
						$MISSING = 0;
					}
				}
				if ( $MISSING ) {
					#SDP::Core::printDebug(" MISSING", $FOUND);
					push(@MISSING_RESOURCES, $VALID) if ( $MISSING );
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkResourceList(): Node is not a member of the cluster, skipping resource test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkResourceList(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$RCODE = scalar @MISSING_RESOURCES;
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Check the NCS Resource Priority list for missing resources: @MISSING_RESOURCES");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "All configured NCS resources match cluster resources list");
	}
	#SDP::Core::printDebug("< checkResourceList", "Missing Resources: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @RESOURCE_LIST = getResourceList();
	checkResourceList(@RESOURCE_LIST);
SDP::Core::printPatternResults();
exit;

