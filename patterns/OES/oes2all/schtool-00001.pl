#!/usr/bin/perl

# Title:       NCP Server Objects from Novell Schema Tool
# Description: Optional attributes are missing from the object NCP Server objectclass after running the Novell Schema Tool.
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
	PROPERTY_NAME_CATEGORY."=NCP",
	PROPERTY_NAME_COMPONENT."=Attributes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004947",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=559518"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkNCSchema {
	SDP::Core::printDebug('> checkNCSchema', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'y2log.txt';
	my $SECTION = '/var/log/YaST2/y2log';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $LINE = 0;
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			next if ( /^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /NovellSchematool\.ycp.*schema file to extend.*ncpserver\.ldif/ ) { # only check for the ldif file if the NovellSchematool was run.
					SDP::Core::printDebug("STATE on: $LINE", $_);
					$RCODE++;
					last;
				} elsif ( /NovellSchematool module finished/ ) {
					SDP::Core::printDebug("STATE on->off: $LINE", $_);
					$STATE = 0;
				}
			} else {
				if ( /NovellSchematool\.ycp.*entering ExtendSchema/ ) { # Make sure the Novell Schema Tool was executed.
					SDP::Core::printDebug("STATE off->on: $LINE", $_);
					$STATE = 1;
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkNCSchema", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
SDP::Core::updateStatus(STATUS_ERROR, "ABORT: OES not installed, skipping schema check.") if ( ! $HOST_INFO{'oes'} );
if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'},'2.0.1') > 0 ) {
	my $SCHEMA_CHECK = 0;
	my $RPM_NAME = 'novell-schema';
	my $VERSION_TO_COMPARE = '1.0.0-68';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed, Skipping schema check.");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed, Skipping schema check.");
	} else {
		$SCHEMA_CHECK++ if ( $RPM_COMPARISON == 0 );
	}
	$RPM_NAME = 'yast2-novell-schematool';
	$VERSION_TO_COMPARE = '2.13.1-41';
	$RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed, Skipping schema check.");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed, Skipping schema check.");
	} else {
		$SCHEMA_CHECK++ if ( $RPM_COMPARISON == 0 );
	}
	if ( $SCHEMA_CHECK > 1 ) {
		if ( checkNCSchema() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Novell Schema Tool for NCS may have damaged the NCP Server objects.");
		} else {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Do not use Novell Schema Tool before reading this TID.");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Novell Schema Tool for NCS validated.");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ABORT: OES2 SP2 not installed, skipping schema check.");
}
SDP::Core::printPatternResults();
exit;

