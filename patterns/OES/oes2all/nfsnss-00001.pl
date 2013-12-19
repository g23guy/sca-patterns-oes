#!/usr/bin/perl

# Title:       OES Compatibility issues between NSS and NFS
# Description: Having an OES 2 server NFS export of an NSS file system has some unique needs and concerns
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
	PROPERTY_NAME_CATEGORY."=NSS",
	PROPERTY_NAME_COMPONENT."=NFS Export",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005949",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=560993"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub getNssMounts {
	SDP::Core::printDebug('> getNssMounts', 'BEGIN');
	my @ACTIVE_MOUNTS = ();
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'fs-diskio.txt';
	my $SECTION = 'mount';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /type nssvol/i ) {
				SDP::Core::printDebug("  getNssMounts PROCESSING", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				push(@ACTIVE_MOUNTS, $LINE_CONTENT[2]);
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getNssMounts(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< getNssMounts", "Returns: @ACTIVE_MOUNTS");
	return @ACTIVE_MOUNTS;
}

sub validateExports {
	my $EXREF = $_[0];
	SDP::Core::printDebug('> validateExports', "@$EXREF");
	my $RCODE = 0;
	my @INVALID_CRIT = ();
	my @INVALID_WARN = ();
	my $CHECK = '';
	my $LINE = '';
#	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'nfs.txt';
	my $SECTION = '/etc/exports';
	my @CONTENT = ();
	my %REQUIRED = (
		'fsid' => 1,
		'no_root_squash' => 1,
		'sync' => 1,
	);

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $LINE (@CONTENT) {
			next if ( $LINE =~ m/^$/ ); # Skip blank lines
			my $SKIPPED = 0;
			my $CHECKED = '';
			my @LINE_CONTENT = ();
			@LINE_CONTENT = split(/\s+/, $LINE);
			my $THIS_MOUNT = shift @LINE_CONTENT; # remove the mount point, consider only the options
			my $INVALID_MOUNT = 0;
			SDP::Core::printDebug("  validateExports CHECKING", $LINE);
			SDP::Core::printDebug("  validateExports  -THIS_MOUNT", $THIS_MOUNT);
			SDP::Core::printDebug("  validateExports  -ALL OPTIONS", "@LINE_CONTENT");
			foreach $CHECKED (@LINE_CONTENT) {
				$CHECKED =~ s/.*\(|\).*//g; # parse out only the option values
				my @SET = ();
				my $FOUND_REQUIRED = 0;
				SDP::Core::printDebug("  validateExports  --OPTIONS", "$CHECKED");
				@SET = split(/,/, $CHECKED);
				foreach $_ (@SET) {
					s/=.*//g; # prune value
					SDP::Core::printDebug("  validateExports  --OPT", $_);
					if ( $REQUIRED{$_} ) {
						$FOUND_REQUIRED++;
					}
				}
				my $RKEYS = scalar keys(%REQUIRED);
				SDP::Core::printDebug("  validateExports  --INVALID?", "FOUND_REQUIRED=$FOUND_REQUIRED, keys(\%REQUIRED)=$RKEYS");
				if ( $FOUND_REQUIRED < $RKEYS ) {
					$INVALID_MOUNT = 1;
					last;
				}
			}

			foreach $CHECK (@$EXREF) {
				if ( $THIS_MOUNT =~ m/$CHECK/ ) {
					push(@INVALID_CRIT, $THIS_MOUNT) if ( $INVALID_MOUNT );
					SDP::Core::printDebug("  validateExports  -PUSH CRIT", $THIS_MOUNT);
					$SKIPPED = 1;
					last;
				}
			}
			if ( ! $SKIPPED ) {
				if ( $LINE =~ m/\/media\/nss\//i ) {
					push(@INVALID_WARN, $THIS_MOUNT) if ( $INVALID_MOUNT );
					SDP::Core::printDebug("  validateExports  -PUSH WARN", $THIS_MOUNT);
				}
			}
		}
		$RCODE = scalar @INVALID_CRIT + scalar @INVALID_WARN;
		if ( $RCODE ) {
			if ( $#INVALID_CRIT >= 0 ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Validate NFS export configuration on mounted NSS volumes: @INVALID_CRIT");
			}
			if ( $#INVALID_WARN >= 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Validate NFS export configuration on NSS volumes: @INVALID_WARN");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No NFS export configuration issue observed for NSS volumes");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: validateExports(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< validateExports", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my %HOST_INFO = SDP::SUSE::getHostInfo();
if ( SDP::Core::compareVersions($HOST_INFO{'oesversion'}, 2) >= 0 && SDP::Core::compareVersions($HOST_INFO{'oesversion'}, 3) < 0 ) {
	my $SERVICE_NAME = 'nfsserver';
	my $NSSVOL = '';
	my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
	if ( $SERVICE_INFO{'running'} > 0 ) {
		my @NSS_MOUNTS = getNssMounts();
		if ( $#NSS_MOUNTS >= 0 ) {
			validateExports(\@NSS_MOUNTS);
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Requires mounted OES2 NSS volumes, skipping NFS test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Requires NFS running on OES2, skipping NFS test");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "Requires OES2, skipping NFS test");
}
SDP::Core::printPatternResults();
exit;

