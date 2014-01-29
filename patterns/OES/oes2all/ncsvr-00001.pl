#!/usr/bin/perl

# Title:       Clustered Volume Resource Errors
# Description: Some volume resource object errors may need to be recreated
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
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Volume",
	PROPERTY_NAME_COMPONENT."=Objects",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006969"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub validateVolumeResources {
	SDP::Core::printDebug('> validateVolumeResources', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-ncsvr.txt';
	my $SECTION = '/usr/lib/supportconfig/plugins/ncsvr';
	my @CONTENT = ();
	my @BADVR = ();
	my $VRFOUND = 0;
	my $CRITICAL_ERRORS = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( m/^(.*) Volume Resource Status:\s*Errors/i ) {
				SDP::Core::printDebug("VR BAD", $_);
				$VRFOUND++;
				push(@BADVR, $1);
			} elsif ( m/Missing Objects:\s*(.*)/i ) {
				$CRITICAL_ERRORS++ if ( $1 > 0 );
			} elsif ( m/Mismatched Object Links:\s*(.*)/i ) {
				$CRITICAL_ERRORS++ if ( $1 > 0 );
			} elsif ( m/.*Volume Resource Status:\s*Pass/i ) {
				SDP::Core::printDebug("VR GOOD", $_);
				$VRFOUND++;
			} elsif ( m/#!\// ) {
				SDP::Core::printDebug("}} END HERE", '');
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: validateVolumeResources(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$RCODE = scalar @BADVR;
	if ( $VRFOUND ) {
		if ( $RCODE ) {
			if ( $CRITICAL_ERRORS ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Detected Clustered Volume Resource Errors on: @BADVR, Review plugin-ncsvr.txt");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "Detected Clustered Volume Resource Errors on: @BADVR, Review plugin-ncsvr.txt");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "All Clustered Volume Resources Passed eDirectory Validation");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No Clustered Volume Resources, Skipping");
	}
	SDP::Core::printDebug("< validateVolumeResources", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	validateVolumeResources();
SDP::Core::printPatternResults();
exit;

