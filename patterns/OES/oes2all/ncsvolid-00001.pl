#!/usr/bin/perl

# Title:       Unique NCS Volume IDs
# Description: Detects duplicate volume IDs in NCS load scripts
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
	PROPERTY_NAME_COMPONENT."=ID",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=3001221",
	"META_LINK_TID2=http://www.novell.com/support/kb/doc.php?id=7008689"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getVolIDHash {
	SDP::Core::printDebug('> getVolIDHash', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'novell-ncs.txt';
	my @FILE_SECTIONS = ();
	my $SECTION = '';
	my @CONTENT = ();
	my %HASH = ();
	my $KEY;
	my $VALUE;
	my $NCP;


	if ( SDP::Core::listSections($FILE_OPEN, \@FILE_SECTIONS) ) {
		foreach $SECTION (@FILE_SECTIONS) {
			if (( $SECTION =~ m/\.load$/ ) && ( $SECTION !~ m/_Template\.load$/ )) {
				@CONTENT = ();
				SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT);
				foreach $NCP (@CONTENT) {
					next if ( $NCP =~ m/^\s*$/ ); # Skip blank lines
					@LINE_CONTENT = ();
					if ( $NCP =~ m/ncpcon mount/ ) {
						SDP::Core::printDebug(" PROCESSING", $NCP);
						@LINE_CONTENT = split(/\s+/, $NCP);
						my $VOLID = $LINE_CONTENT[$#LINE_CONTENT];
						if ( $VOLID =~ m/=/ ) {
							( $KEY, $VALUE ) = split(/=/, $VOLID);
							$HASH{$KEY} = $VALUE;
							SDP::Core::printDebug(" ENTRY", "$KEY = $VALUE");
						} # found volume assigned
					} # ncpcon mount search
				} # foreach section line
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: myFunction(): No sections found in $FILE_OPEN");
	}
	if ( $OPT_LOGLEVEL >= LOGLEVEL_DEBUG ) {
		print(' %HASH                          = ');
		while ( ($KEY, $VALUE) = each(%HASH) ) {
			print("$KEY => \"$VALUE\"  ");
		}
		print("\n");
	}

	SDP::Core::printDebug("< getVolIDHash", "Returns: $RCODE");
	return %HASH;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $PKG_NAME = 'novell-cluster-services';
	if ( SDP::SUSE::packageInstalled($PKG_NAME) ) {
		my %VOLIDS = getVolIDHash();
		my %DUP;
		my $VALUE;
		while ( (undef, $VALUE) = each(%VOLIDS) ) {
			$DUP{$VALUE} = 1;
		}
		my $VOLID_COUNT = keys(%VOLIDS);
		my $DUP_COUNT = keys(%DUP);
		if ( $VOLID_COUNT != $DUP_COUNT ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Duplicate NCS Volume IDs in load scripts with 'ncpcon mount'");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "SKIPPED: No duplicate NCS Volume IDs found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Package NOT Installed: $PKG_NAME");
	}
SDP::Core::printPatternResults();
exit;


