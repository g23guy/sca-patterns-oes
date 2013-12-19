#!/usr/bin/perl

# Title:       OES2 Linux target needs the correct entries in smdrd.conf
# Description: For proper sms discovery, the smdrd.conf should have these entries: hosts: enable slp: enable ip: (Correct Linux server IP address where smdrd will listen)
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
	PROPERTY_NAME_CATEGORY."=Migration",
	PROPERTY_NAME_COMPONENT."=Configuration",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001767"
);

##############################################################################
# Local Function Definitions
##############################################################################
sub boundIPAddresses {
	SDP::Core::printDebug('> boundIPAddresses', 'BEGIN');
	my @LIST_IPS = ();
	my $FILE_OPEN = 'network.txt';
	my $SECTION = 'ifconfig -a';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my $IPDEF = '';
	my $MINSECTIONS = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		$MINSECTIONS++;
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			s/^\s+//; # remove leading white space
			if ( /^inet/ ) {
				SDP::Core::printDebug("  boundIPAddresses TAKE ACTION ON", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				foreach $IPDEF (@LINE_CONTENT) {
					if ( $IPDEF =~ /^addr:(.*)/i ) {
						if ( $1 !~ /127\.0\.0/ ) {
							SDP::Core::printDebug("  boundIPAddresses  -IPDEF", $IPDEF);
							push(@LIST_IPS, $1);
						} else {
							SDP::Core::printDebug("  boundIPAddresses  EXCLUDE", $IPDEF);
						}
					}
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	SDP::Core::printDebug("  boundIPAddresses LIST_IPS", "@LIST_IPS");
	SDP::Core::printDebug("< boundIPAddresses", "Returns: $#LIST_IPS");
	return @LIST_IPS;
}

sub ipInBoundList {
	my $TESTIP = $_[0];
	SDP::Core::printDebug('> ipInBoundList', "Testing: $TESTIP");
	my $RCODE = 0;
	my @ALL_BOUND_IPS = boundIPAddresses();
	my $BOUNDIP = '';

	foreach $BOUNDIP (@ALL_BOUND_IPS) {
		SDP::Core::printDebug('  ipInBoundList TESTIP:BOUNDIP', "$TESTIP:$BOUNDIP");
		if ( $BOUNDIP eq $TESTIP ) { $RCODE=1; last; }
	}
	SDP::Core::printDebug("< ipInBoundList", "Returns: $RCODE");
	return $RCODE;
}

sub smdrConfig {
	SDP::Core::printDebug('> smdrConfig', 'BEGIN');
	my $HEADER_LINES = 0;
	my $FILE_OPEN = 'etc.txt';
	my $SECTION = 'smdrd.conf';
	my @CONTENT = ();
	my @LINE_CONTENT = ();
	my @CURRENT_IPSBOUND = ();
	my @ALL_IP_BOUND = boundIPAddresses();
	my $LINE = 0;
	my $RCODE = 0;
	my $FOUND_SLP = 0;
	my $FOUND_HOSTS = 0;
	my $FOUND_IP = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( $LINE++ < $HEADER_LINES ); # Skip header lines
			next if ( /^\s*$/ );                   # Skip blank lines
			if ( /^SLP:/i ) {
				SDP::Core::printDebug("  smdrConfig LINE $LINE", $_);
				$FOUND_SLP = 1;
				@LINE_CONTENT = split(/:\s+/, $_);
				if ( $LINE_CONTENT[1] =~ /enable/i ) {
					SDP::Core::updateStatus(STATUS_PARTIAL, "SLP Enabled");
				} else {
					SDP::Core::updateStatus(STATUS_CRITICAL, "SLP NOT Enabled");
				}
			}
			if ( /^HOSTS:/i ) {
				SDP::Core::printDebug("  smdrConfig LINE $LINE", $_);
				$FOUND_HOSTS = 1;
				@LINE_CONTENT = split(/:\s+/, $_);
				if ( $LINE_CONTENT[1] =~ /enable/i ) {
					SDP::Core::updateStatus(STATUS_PARTIAL, "HOSTS Enabled");
				} else {
					SDP::Core::updateStatus(STATUS_CRITICAL, "HOSTS NOT Enabled");
				}
			}
			if ( /^IP:/i ) {
				SDP::Core::printDebug("  smdrConfig LINE $LINE", $_);
				$FOUND_IP = 1;
				@LINE_CONTENT = split(/:\s+/, $_);
				if ( $LINE_CONTENT[1] =~ /default/i ) {
					if ( $#ALL_IP_BOUND > 0 ) { # 0 is the index to the first ip, so >0 means more than 1 bound ip address
						SDP::Core::updateStatus(STATUS_CRITICAL, "IP using Default, Multiple IPs Bound, $_");
					} else {
						SDP::Core::updateStatus(STATUS_WARNING, "IP using Default, change to an IP address");
					}
				} else {
					if ( ipInBoundList($LINE_CONTENT[1]) ) {
						SDP::Core::updateStatus(STATUS_PARTIAL, "IP Address Defined");
					} else {
						SDP::Core::updateStatus(STATUS_CRITICAL, "IP Address is not bound on the server, $_");
					}
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	$RCODE = $FOUND_SLP + $FOUND_HOSTS + $FOUND_IP;
	if ( $RCODE != 3 ) {
		if ( ! $FOUND_SLP ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing SLP entry in smdrd.conf");
		}
		if ( ! $FOUND_HOSTS ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing HOSTS entry in smdrd.conf");
		}
		if ( ! $FOUND_IP ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Missing IP entry in smdrd.conf");
		}
	}

	SDP::Core::printDebug("< smdrConfig", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
smdrConfig();
SDP::Core::printPatternResults();
exit;



