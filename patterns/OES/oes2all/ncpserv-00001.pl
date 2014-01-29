#!/usr/bin/perl

# Title:       Cluster resource goes comatose with NSS error 20892
# Description: When migrating a resource to another node, the resource may go comatose
# Modified:    2013 Jun 21

# check oes2 sp1 novell-ncpserv version, it may be different than oes2 sp2

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
	PROPERTY_NAME_COMPONENT."=Comatose",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005375",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=560427"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub isNCSCluster {
	SDP::Core::printDebug('> isNCSCluster', 'BEGIN');
	my $RCODE = 0;
	my $SERVICE_NAME = 'novell-ncs';
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	$RCODE++ if ( $SERVICE_INFO{'running'} );
	SDP::Core::printDebug("< isNCSCluster", "Returns: $RCODE");
	return $RCODE;
}

sub checkComatoseNCPServ {
	SDP::Core::printDebug('> checkComatoseNCPServ', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my $SECTION = '';
	my @SECTION_CONTENT = ();
	my @CONTENT = ();
	my $RESOURCE = '';
	my @FILE_SECTIONS = ();

	if ( SDP::Core::listSections($FILE_OPEN, \@FILE_SECTIONS) ) {
		foreach $SECTION (@FILE_SECTIONS) {
			if ( $SECTION =~ /\.load\.out/ ) {
				SDP::Core::printDebug("CHECKING", $SECTION);
				@CONTENT = (); # reset content
				if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
					foreach $_ (@CONTENT) {
						next if ( /^\s*$/ ); # Skip blank lines
						if ( /Error 20892/i ) {
							SDP::Core::printDebug("PROCESSING", $_);
							@SECTION_CONTENT = split(/\//, $SECTION);
							$RESOURCE = pop(@SECTION_CONTENT);
							$RESOURCE =~ s/\.load\.out//g;
							$RCODE++;
							last;
						}
					}
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
				}
			}
			last if $RCODE;
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No sections found in $FILE_OPEN");
	}

	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Possible comatose resource with NSS error 20892: $RESOURCE");
	} else {
		SDP::Core::updateStatus(STATUS_WARNING, "NCP Server resource(s) susceptible to NSS error 20892");
	}
	SDP::Core::printDebug("< checkComatoseNCPServ", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( isNCSCluster() ) {
		my $RPM_NAME = 'novell-ncpserv';
		my %HOST_INFO = SDP::SUSE::getHostInfo();
		if ( $HOST_INFO{'oesmajor'} != 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 required, skipping comatose ncpserv test");
		} elsif ( $HOST_INFO{'oespatchlevel'} > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "Newer than OES2 SP2, skipping comatose ncpserv test");
		} else {
			my $VERSION_TO_COMPARE = '2.0.2-0.11.1'; # assume oes2 sp2
			$VERSION_TO_COMPARE = '2.0.1-30' if ( $HOST_INFO{'oespatchlevel'} < 2 ); # less than oes2 sp2
			my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
			if ( $RPM_COMPARISON == 2 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
			} elsif ( $RPM_COMPARISON > 2 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
			} else {
				if ( $RPM_COMPARISON < 0 ) {
					checkComatoseNCPServ();
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "novell-ncpserv-$VERSION_TO_COMPARE or higher avoids an NSS error 20892");
				}                       
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing NCS Cluster, skipping comatose ncpserv test");
	}
SDP::Core::printPatternResults();
exit;

