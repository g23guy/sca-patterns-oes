#!/usr/bin/perl

# Title:       Novell NSS fails due to missing Required-Start
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
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#  Authors/Contributors:
#  	Jason Record (jrecord@suse.com)
#
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
	PROPERTY_NAME_CATEGORY."=NSS",
	PROPERTY_NAME_COMPONENT."=Startup",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006574"
);

use constant REQS_REQUIRED => 2; # novell-nss:# Required-Start: $remote_fs $syslog $named ndsd namcd

##############################################################################
# Local Function Definitions
##############################################################################

sub usingNSS {
	SDP::Core::printDebug('> usingNSS', 'BEGIN');
	my $RCODE = 0;
	my $SERVICE_NAME = 'novell-nss';

	if ( SDP::SUSE::packageInstalled($SERVICE_NAME) ) {
		my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
		if ( $SERVICE_INFO{'runlevelstatus'} > 0 ) {
			$RCODE++;
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: usingNSS(): $SERVICE_INFO{'name'} turned off, skipping Required-Start test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: usingNSS(): Novell NSS not installed, skipping Required-Start test");
	}
	SDP::Core::printDebug("< usingNSS", "Returns: $RCODE");
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
		SDP::Core::updateStatus(STATUS_WARNING, "Novell NSS required service turned off at boot: ndsd or namcd");
	}
	SDP::Core::printDebug("< checkReqsOnBoot", "Returns: $RCODE");
	return $RCODE;
}

sub checkReqsRunning {
	SDP::Core::printDebug('> checkReqsRunning', 'BEGIN');
	my $RCODE = 0;
	my $REQS_NAMCD = 0;
	my $REQS_NDSD = 0;
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
	if ( ! $REQS_NAMCD ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Novell LUM (namcd) is not running, NSS will FAIL");
	} elsif ( ! $REQS_NDSD ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Novell eDirectory (ndsd) is not running, NSS will FAIL");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Novell NSS Required Services are Running: ndsd, namcd");
	}
	SDP::Core::printDebug("< checkReqsRunning", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
if ( usingNSS() ) {
	checkReqsOnBoot();
	checkReqsRunning();
}
SDP::Core::printPatternResults();
exit;

