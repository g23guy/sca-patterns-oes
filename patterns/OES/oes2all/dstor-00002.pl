#!/usr/bin/perl

# Title:       NSS Shadow Volume Data Unavailable
# Description: Shadow volume data may become unavailable after NDSD restart
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
use SDP::OESLinux;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=DST",
	PROPERTY_NAME_COMPONENT."=Volumes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008950",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=702090"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getSuspectVolumes {
	SDP::Core::printDebug('> getSuspectVolumes', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncp.txt';
	my $ARRAY_REF = $_[0];
	my @CONTENT = ();
	my @PATH = ();
	my $STATE = 0;
	my $CONTENT_FOUND = 0;
	my $VOL = '';
	my $PRI_VOL = '';
	my $SHA_VOL = '';
	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					$STATE = 0;
					$VOL = '';
					$PRI_VOL = '';
					$SHA_VOL = '';
					@PATH = ();
					SDP::Core::printDebug("  getSuspectVolumes DONE", "State Off");
				} elsif ( /^\s*Mount point:\s*(\S*)/i ) { # mount point needed
					@PATH = split(/\//, $1);
					$PRI_VOL = $PATH[$#PATH];
					SDP::Core::printDebug("  getSuspectVolumes Primary", $_);
				} elsif ( /^\s*Shadow Mount point:\s*(\S*)/i ) { # shadow mount point needed
					$SHA_VOL = $1;
					SDP::Core::printDebug("  getSuspectVolumes Shadow", $_);
					if ( $SHA_VOL !~ m/\(null\)/i ) {
						@PATH = split(/\//, $SHA_VOL);
						$SHA_VOL = $PATH[$#PATH];
						$CONTENT_FOUND = 1;
						if ( $PRI_VOL =~ m/^$VOL/ && $SHA_VOL =~ m/^$VOL/ ) {
							SDP::Core::printDebug("  getSuspectVolumes PUSHING", "Volume: $VOL, Primary: $PRI_VOL, Shadow: $SHA_VOL");
							push(@$ARRAY_REF, $VOL);
						} else {
							SDP::Core::printDebug("  getSuspectVolumes Skipping", "Volume: $VOL, Primary: $PRI_VOL, Shadow: $SHA_VOL");
						}
					}
				}
			} elsif ( /^# \/sbin\/ncpcon volume (\S*)/ ) { # Section
				$VOL = $1;
				$STATE = 1;
				SDP::Core::printDebug("  getSuspectVolumes CHECK", "Section: $_");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getSuspectVolumes(): Cannot load file: $FILE_OPEN");
	}
	if ( $CONTENT_FOUND ) {
		$RCODE = scalar @$ARRAY_REF;
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getSuspectVolumes(): No Shadow Mount Points Found, skipping test");
	}
	SDP::Core::printDebug("< getSuspectVolumes", "Returns: $RCODE");
	return $RCODE;
}
##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( SDP::OESLinux::shadowVolumes() ) {
	my %HOST_INFO = SDP::SUSE::getHostInfo();
	if ( $HOST_INFO{'oesmajor'} == 2 && $HOST_INFO{'oespatchlevel'} == 3 ) {
		my @WARN_VOLS = ();
		if ( getSuspectVolumes(\@WARN_VOLS) ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Shadow volume files may go missing after an ndsd restart on volume(s): @WARN_VOLS");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Primary and Shadow volume names are sufficiently unique");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: OES2SP3 required, skipping DST test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: DST Volumes required, skipping test");
}
SDP::Core::printPatternResults();
exit;

