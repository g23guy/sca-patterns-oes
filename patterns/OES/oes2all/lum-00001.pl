#!/usr/bin/perl

# Title:       Admin is not LUM enabled
# Description: NRM fails when admin is not LUM enabled
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
	PROPERTY_NAME_CATEGORY."=NRM",
	PROPERTY_NAME_COMPONENT."=LUM Admin",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7009282",
	"META_LINK_TID2=http://www.suse.com/support/kb/doc.php?id=7002981"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub nsswitchNAM {
	SDP::Core::printDebug('> nsswitchNAM', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'pam.txt';
	my $SECTION = 'nsswitch.conf';
	my @CONTENT = ();
	my $BOTH = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^passwd:.*nam / ) {
				$BOTH++;
			} elsif ( /group:.*nam / ) {
				$BOTH++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nsswitchNAM(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$RCODE++ if ( $BOTH > 1 );
	SDP::Core::printDebug("< nsswitchNAM", "Returns: $RCODE");
	return $RCODE;
}

sub missingAdmin {
	SDP::Core::printDebug('> missingAdmin', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'pam.txt';
	my $SECTION = '/etc/passwd';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^admin:/ ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdmin(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdmin(): Found admin user in local files, skipping LUM") if ( $RCODE );

	$SECTION = 'getent passwd';
	@CONTENT = ();
	$RCODE = 1;
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^admin:/ ) {
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdmin(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< missingAdmin", "Returns: $RCODE");
	return $RCODE;
}

sub missingAdminGroup {
	SDP::Core::printDebug('> missingAdminGroup', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'pam.txt';
	my $SECTION = '/etc/group';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^admingroup:/ ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdminGroup(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdminGroup(): Found admin user in local files, skipping LUM") if ( $RCODE );

	$SECTION = 'getent group';
	@CONTENT = ();
	$RCODE = 1;
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^admingroup:/ ) {
				$RCODE = 0;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingAdminGroup(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< missingAdminGroup", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( nsswitchNAM() ) {
	my $MISSING = 0;
	my $MISSING_STR = "";
	if ( missingAdmin() ) {
		$MISSING_STR = "admin";
		$MISSING++;
	}
	if ( missingAdminGroup() ) {
		if ( $MISSING ) {
			$MISSING_STR = "admin and admingroup";
		} else {
			$MISSING_STR = "admingroup";
		}
		$MISSING++;
	}
	if ( $MISSING ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Missing LUM enabled $MISSING_STR, NRM will fail");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "OES admin and admingroup found") if ( ! $MISSING );
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: No LUM in name service switch, skipping LUM test.");
}
SDP::Core::printPatternResults();
exit;


