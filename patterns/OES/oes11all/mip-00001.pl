#!/usr/bin/perl

# Title:       The cluster Master IP Resource is blank
# Description: iManager can cause the Master_IP_Resource scripts to be blank
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
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Master",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7006781"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub masterIpResourcePopulated {
	SDP::Core::printDebug('> masterIpResourcePopulated', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = 'Master_IP_Address_Resource.load$';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /.*/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: masterIpResourcePopulated(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< masterIpResourcePopulated", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $RPM_NAME = 'novell-plugin-cluster-services';
	my $BAD_RPMVER = '3.3.282-0.5';
	my @RPM_INFO = SDP::SUSE::getRpmInfo($RPM_NAME);
	if ( $#RPM_INFO < 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed, Skipping NCS iManager Plugin test");
	} elsif ( $#RPM_INFO > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple $RPM_NAME RPMs Installed, Skipping NCS iManager Plugin test");
	} else {
		if ( SDP::Core::compareVersions($BAD_RPMVER, $RPM_INFO[0]{'version'}) == 0 ) { #bad rpm installed
			if ( masterIpResourcePopulated() > 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "iManager NCS plugin may delete the Master IP Resource scripts after migration");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "iManager NCS plugin issue, the Master IP Resource load script is blank");
			}
		} else {
			if ( masterIpResourcePopulated() > 0 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "iManager NCS plugin and Master IP Resource scripts appear unaffected");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Potential iManager NCS plugin issue, the Master IP Resource load script is blank");
			}
		}
	}

SDP::Core::printPatternResults();

exit;

