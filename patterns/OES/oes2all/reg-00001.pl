#!/usr/bin/perl

# Title:       OES Update Catalog Missing After Registration
# Description: Checks if the OES Updates catalog is missing and preventing update registration.
# Modified:    2013 Jun 25

##############################################################################
#  Copyright (C) 2013-2012 SUSE LLC
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
	PROPERTY_NAME_CATEGORY."=Update",
	PROPERTY_NAME_COMPONENT."=Catalog",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3150078",
	"META_LINK_Doc=http://www.novell.com/documentation/oes2/inst_oes_lx/?page=/documentation/oes2/inst_oes_lx/data/blv0wen.html"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub validateUpdateChannels {
	SDP::Core::printDebug('> validateUpdateChannels', 'BEGIN');
	my $FILE_OPEN = 'updates.txt';
	my $SECTION = 'rug ca';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $UP_SLE = '';
	my $UP_OES = '';
	my $UPS_SLE = -1; # no channel
	my $UPS_OES = -1;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			next if ( /-*\+-*\+-*/ ); # skip header line
			$_ =~ s/\s+\|\s+/\|/g; # remove white space
			$_ =~ s/^\s+|\s+$//g;
			# get the update channels needed if subscribed to them
			@LINE_CONTENT = split(/\|/, $_);
			if ( $LINE_CONTENT[1] =~ /SLES10-SP.-Updates/i ) {
				if ( $LINE_CONTENT[0] =~ /yes/i ) {
					$UPS_SLE = 1; # sub'd to channel
				} else {
					$UPS_SLE = 0; # not sub'd to channel, but it exists.
				}
				$UP_SLE = $LINE_CONTENT[1];
			} elsif ( $LINE_CONTENT[1] =~ /OES2.*Updates/i ) {
				if ( $LINE_CONTENT[0] =~ /yes/i ) {
					$UPS_OES = 1; # sub'd to channel
				} else {
					$UPS_OES = 0; # not sub'd to channel, but it exists.
				}
				$UP_OES = $LINE_CONTENT[1];
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $UPS_SLE >= 0 && $UPS_OES >= 0 ) {
		if ( $UP_SLE =~ /SLES10-SP4-Updates/ && $UP_OES =~ /OES2-SP3-Updates/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Update Catalogs Verified: $UP_SLE, $UP_OES");
		} elsif ( $UP_SLE =~ /SLES10-SP3-Updates/ && $UP_OES =~ /OES2-SP3-Updates/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Update Catalogs Verified: $UP_SLE, $UP_OES");
		} elsif ( $UP_SLE =~ /SLES10-SP3-Updates/ && $UP_OES =~ /OES2-SP2-Updates/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Update Catalogs Verified: $UP_SLE, $UP_OES");
		} elsif ( $UP_SLE =~ /SLES10-SP2-Updates/ && $UP_OES =~ /OES2-SP1-Updates/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Update Catalogs Verified: $UP_SLE, $UP_OES");
		} elsif ( $UP_SLE =~ /SLES10-SP1-Updates/ && $UP_OES =~ /OES2-Updates/ ) {
			SDP::Core::updateStatus(STATUS_ERROR, "OES2 Update Catalogs Verified: $UP_SLE, $UP_OES");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "Mismatched OES2 Update Catalogs: $UP_SLE, $UP_OES");
		}
	} else {
		my $CH_FAIL = '';
		$CH_FAIL = "SLES10" if ( ! $UP_SLE );
		if ( ! $UP_OES ) {
			if ( $CH_FAIL ) { $CH_FAIL = "$CH_FAIL and OES2"; } else { $CH_FAIL = "OES2"; }
		}
		SDP::Core::updateStatus(STATUS_CRITICAL, "Missing Update Catalog for: $CH_FAIL");
	}
	SDP::Core::printDebug("< validateUpdateChannels", "SLE: '$UP_SLE' ($UPS_SLE), OES: '$UP_OES' ($UPS_OES)");
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( compareKernel(SLE10SP1) >= 0 && compareKernel(SLE11GA) < 0 ) {
		my %HOST_INFO = SDP::SUSE::getHostInfo();

		if ( $HOST_INFO{'oes'} ) {
			validateUpdateChannels();
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Error: OES Updates Not Applicable, OES Not Installed");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: Outside the kernel scope, requires SLE10SP1 to SLE11GA");
	}
SDP::Core::printPatternResults();

exit;


