#!/usr/bin/perl

# Title:       NCS cluster resources go comatose
# Description: Cluster resources go comatose because ncpcon bind statement fails
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Comatose",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008963",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=693756"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub ncpconErrors {
	#SDP::Core::printDebug('> ncpconErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my @CONTENT = ();
	my $STATE = 0;
	my $BINDSTATE = 0;
	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					$STATE = 0;
					#SDP::Core::printDebug(" DONE", "State Off");
				} elsif ( $BINDSTATE ) {
					if ( /^\+/ ) {
						$BINDSTATE = 0;
						#SDP::Core::printDebug(" OFF", "ncpcon bind");
					} elsif ( /FAILED/ ) {
						#SDP::Core::printDebug(" FAILED", "ncpcon bind");
						$RCODE++;
						last;
					}
				} elsif ( /^\+ ncpcon bind/ ) { # Section content needed
					$BINDSTATE = 1;
					#SDP::Core::printDebug(" NCPCON", "Check bind: $_");
				}
			} elsif ( /^# .*\/ncs\/(.*)\.load\.out$/ ) { # Section
				my $RESOURCE = $1;
				$STATE = 1;
				#SDP::Core::printDebug("CHECK", "Section: $_");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ncpconErrors(): Cannot load file: $FILE_OPEN");
	}
	#SDP::Core::printDebug("< ncpconErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::OESLinux::ncsActive() ) {
		my $SERVICE_NAME = 'slpd';
		my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
		if ( $SERVICE_INFO{'running'} > 0 ) {
			my $RPM_NAME = 'openslp';
			my $VERSION_TO_COMPARE = '1.2.0-22.36.4';
			my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
			if ( $RPM_COMPARISON == 2 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
			} elsif ( $RPM_COMPARISON > 2 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
			} else {
				if ( $RPM_COMPARISON < 0 ) {
					if ( ncpconErrors() ) {
						SDP::Core::updateStatus(STATUS_CRITICAL, "Detected ncpcon errors or comatose NCS resources, update system to apply $RPM_NAME-$VERSION_TO_COMPARE or higher");
					} else {
						SDP::Core::updateStatus(STATUS_WARNING, "NCS resources may go comatose, update system to apply $RPM_NAME-$VERSION_TO_COMPARE or higher");
					}
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "The installed $RPM_NAME RPM version meets or exceeds version $VERSION_TO_COMPARE, ignoring ncpcon bind");
				}			
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Service $SERVICE_INFO{'name'} is NOT running, skipping ncpcon bind test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "NCS Required to be active, skipping ncpcon bind test");
	}
SDP::Core::printPatternResults();
exit;

