#!/usr/bin/perl

# Title:       Novell NCP2NSS fails due to missing Required-Start
# Description: Required-Start processes must be active before starting this service
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
	PROPERTY_NAME_CATEGORY."=NCP2NSS",
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006594"
);
my $SERVICE = 'NCP';

use constant REQS_REQUIRED => 3; # novell-dfs:# Required-Start: $remote_fs $syslog $named ndsd namcd nss

##############################################################################
# Local Function Definitions
##############################################################################

sub usingNCP {
	SDP::Core::printDebug('> usingNCP', 'BEGIN');
	my $RCODE = 0;
	my $PACKAGE_NAME = 'novell-ncpserv';
	my $SERVICE_NAME = 'ncp2nss';

	if ( SDP::SUSE::packageInstalled($PACKAGE_NAME) ) {
		my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
		if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
			$RCODE++;
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: usingNCP(): $SERVICE_INFO{'name'} turned off, skipping Required-Start test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: usingNCP(): Novell $SERVICE not installed, skipping Required-Start test");
	}
	SDP::Core::printDebug("< usingNCP", "Returns: $RCODE");
	return $RCODE;
}

sub checkReqsOnBoot {
	SDP::Core::printDebug('> checkReqsOnBoot', 'BEGIN');
	my $RCODE = 0;
	my $REQS_ON = 0;
	my $FILE_OPEN = 'chkconfig.txt';
	my $SECTION = 'chkconfig --list';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^namcd.*3\:on.*5\:on/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_ON++;
			} elsif ( /^ndsd.*3\:on.*5\:on/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_ON++;
			} elsif ( /^novell-nss.*3\:on.*5\:on/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_ON++;
			}
			if ( $REQS_ON >= REQS_REQUIRED ) {
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkReqsOnBoot(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( ! $RCODE ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Novell $SERVICE required service turned off at boot: ndsd, namcd or novell-nss");
	}
	SDP::Core::printDebug("< checkReqsOnBoot", "Returns: $RCODE");
	return $RCODE;
}

sub checkReqsRunning {
	SDP::Core::printDebug('> checkReqsRunning', 'BEGIN');
	my $RCODE = 0;
	my $REQS_NAMCD = 0;
	my $REQS_NDSD = 0;
	my $REQS_NSS = 0;
	my $FILE_OPEN = 'basic-health-check.txt';
	my $SECTION = 'ps';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /\/sbin\/namcd/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_NAMCD++;
			} elsif ( /\/sbin\/ndsd/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_NDSD++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkReqsRunning(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	$FILE_OPEN = 'novell-nss.txt';
	$SECTION = 'novell-nss status';
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( m/NSS kernel modules.*running/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_NSS++;
			} elsif ( m/NSS admin volume.*running/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$REQS_NSS++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkReqsRunning(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( ! $REQS_NAMCD ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Novell LUM (namcd) is not running, $SERVICE will FAIL");
	} elsif ( ! $REQS_NDSD ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Novell eDirectory (ndsd) is not running, $SERVICE will FAIL");
	} elsif ( $REQS_NSS < 2 ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Novell NSS (novell-nss) is not running, $SERVICE will FAIL");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Novell $SERVICE Required Services are Running: ndsd, namcd, novell-nss");
	}
	SDP::Core::printDebug("< checkReqsRunning", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( usingNCP() ) {
	checkReqsOnBoot();
	checkReqsRunning();
}
SDP::Core::printPatternResults();
exit;

