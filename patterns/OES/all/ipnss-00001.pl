#!/usr/bin/perl

# Title:       iPrint fails to load with NSS
# Description: Print manager fails to load with nss after upgrading iprint through the channel
# Modified:    2013 Jun 25

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
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=Start",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7004346",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=530230"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub errorLogged {
	SDP::Core::printDebug('> errorLogged', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = '/ipsmd.log';
	my @CONTENT = ();
	my $TMP_FILE = $ARCH_PATH . $FILE_OPEN;

	if ( SDP::Core::fileInArchive($FILE_OPEN) ) {
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /WARNING The kernel has indicated that a gateway, ilprsrvrd or accounting process is gone/i ) {
					SDP::Core::printDebug("PROCESSING", $_);
					$RCODE++;
					last;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_PARTIAL, "ERROR: errorLogged(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	} else {
		SDP::Core::updateStatus(STATUS_PARTIAL, "ERROR: errorLogged(): File not found: $FILE_OPEN");
	}
	SDP::Core::printDebug("< errorLogged", "Returns: $RCODE");
	return $RCODE;
}
##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $IPRINT_BADV='6.1.20090608-1';
	my $IPRINT_GOODV='6.1.20100101';
	my $IPRINT_GOODVSTR='6.1.2010';

	my $RPM_NAME = 'novell-iprint-server';
	my @RPM_INFO = SDP::SUSE::getRpmInfo($RPM_NAME);
	if ( $#RPM_INFO < 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $#RPM_INFO > 0 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple $RPM_NAME RPMs Installed");
	} else {
		if ( SDP::Core::compareVersions($RPM_INFO[0]{'version'}, $IPRINT_BADV) >= 0 && SDP::Core::compareVersions($RPM_INFO[0]{'version'}, $IPRINT_GOODV) < 0 ) {
			if ( errorLogged() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "iPrint Manager fatal errors detected, update system to apply $RPM_NAME-$IPRINT_GOODVSTR or later");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "iPrint Manager susceptible to fatal errors, update system to apply $RPM_NAME-$IPRINT_GOODVSTR or later");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Skipping fatal error check, $RPM_INFO[0]{'name'}-$RPM_INFO[0]{'version'}");
		}
	}
SDP::Core::printPatternResults();

exit;


