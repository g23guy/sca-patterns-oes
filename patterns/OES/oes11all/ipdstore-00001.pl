#!/usr/bin/perl

# Title:       iPrint Driver Store Configuration Errors
# Description: Error: Driver Store could not be configured: Request (SERVER_ERROR) - bad status code (0X500) appears when creating a driver store in iManager
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
	PROPERTY_NAME_CATEGORY."=iPrint",
	PROPERTY_NAME_COMPONENT."=Config",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3023179"
);

my @BADBIN = ();

##############################################################################
# Local Function Definitions
##############################################################################

sub invalidBinConfiguration {
	SDP::Core::printDebug('> invalidBinConfiguration', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'plugin-iPrint.txt';
	my $SECTION = '/opt/novell/iprint/bin/';
	my @CONTENT = ();
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^total/ ) {
					last;
				} elsif ( /\s(iprintcnfg)$/ ) {
					SDP::Core::printDebug("PROCESSING", $_);
					if ( $_ !~ m/\-rwsr\-x\-\-\-.*\sroot\s*www\s*.*iprintcnfg$/ ) {
						SDP::Core::printDebug(" PUSH", $1);
						push(@BADBIN, $1);
					}
				} elsif ( /\s(iprintcnfgproxy)$/ ) {
					SDP::Core::printDebug("PROCESSING", $_);
					if ( $_ !~ m/\-rwxr\-x\-\-\-.*root\s*www\s*.*iprintcnfgproxy$/ ) {
						SDP::Core::printDebug(" PUSH", $1);
						push(@BADBIN, $1);
					}
				}
			} elsif ( /^total/ ) {
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: invalidBinConfiguration(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$RCODE = scalar @BADBIN;
	SDP::Core::printDebug("< invalidBinConfiguration", "Returns: $RCODE");
	return $RCODE;
}

sub errorsLogged {
	SDP::Core::printDebug('> errorsLogged', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'web.txt';
	my $SECTION = 'apache2/error_log';
	my @CONTENT = ();

	if ( SDP::Core::fileInArchive($FILE_OPEN) ) {
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /mod_ipp: Error performing operation IDS_.*_CONFIG: unable to get data back from.*iprintcnfg.*program/i ) {
					SDP::Core::printDebug("PROCESSING", $_);
					$RCODE++;
					last;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_PARTIAL, "ERROR: errorsLogged(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	} else {
		SDP::Core::updateStatus(STATUS_PARTIAL, "ERROR: errorsLogged(): File not found: $FILE_OPEN");
	}
	SDP::Core::printDebug("< errorsLogged", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( invalidBinConfiguration() ) {
		if ( errorsLogged() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Errors Detected; Invalid binary configuration: @BADBIN");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "Invalid binary configuration: @BADBIN");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Valid iprintcnfg and iprintcnfgproxy binary configuration");
	}
SDP::Core::printPatternResults();

exit;

