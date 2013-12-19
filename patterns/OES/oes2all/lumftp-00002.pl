#!/usr/bin/perl

# Title:       nwlogin processes get stuck
# Description: Novell FTP logins through pure-ftpd may fail
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
	PROPERTY_NAME_CATEGORY."=FTP",
	PROPERTY_NAME_COMPONENT."=Logins",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008646",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=694710"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub ftpActive {
	SDP::Core::printDebug('> ftpActive', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'basic-health-check.txt';
	my $SECTION = 'bin/ps';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /\spure-ftpd\s|\/pure-ftpd\s/ ) {
				SDP::Core::printDebug("  ftpActive PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ftpActive(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< ftpActive", "Returns: $RCODE");
	return $RCODE;
}

sub removeServerSet {
	SDP::Core::printDebug('> removeServerSet', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'etc.txt';
	my $SECTION = 'pure-ftpd.conf';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /remote_server.*yes/ ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: removeServerSet(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< removeServerSet", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( $HOST_INFO{'oes'} && $HOST_INFO{'oesmajor'} == 2 && $HOST_INFO{'oespatchlevel'} == 3 ) {
	my $RPM_NAME = 'novell-lum';
	if ( SDP::SUSE::packageInstalled($RPM_NAME) ) {
		if ( ftpActive() ) {
			if ( removeServerSet() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Novell FTP logins may fail, disable remove_server in pure-ftpd.conf");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Novell FTP login issue not detected");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "PureFTP not active, skipping Novell FTP login test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Novell LUM not installed, skipping Novell FTP login test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "OES2SP3 Required, skipping FTP login test");
}
SDP::Core::printPatternResults();
exit;

