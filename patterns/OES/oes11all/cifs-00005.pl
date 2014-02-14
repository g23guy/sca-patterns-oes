#!/usr/bin/perl

# Title:       Adding a Virtual Server is failed
# Description: The nfap attributes are missing from the virtual server object.
# Modified:    2013 Jun 24

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
	PROPERTY_NAME_CATEGORY."=CIFS",
	PROPERTY_NAME_COMPONENT."=Server",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008872"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub detectCIFSError {
	SDP::Core::printDebug('> detectCIFSError', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-ncs.txt';
	my @CONTENT = ();
	my $STATE = 0;
	my $CONTENT_FOUND = 0;
	my $CIFS_FOUND = 0;
	my $CIFS_NCS = 0;
	my $RESOURCE = '';
	my @VSFAILURES = ();
	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					$STATE = 0;
					$CONTENT_FOUND = 0;
					$CIFS_FOUND = 0;
					SDP::Core::printDebug(" DONE", "State Off");
				} elsif ( $CIFS_FOUND ) {
					if ( $CONTENT_FOUND ) {
						if ( /Error Number.*-603/i ) {
							SDP::Core::printDebug(" ERROR", "$RESOURCE - $_");
							push(@VSFAILURES, $RESOURCE);
							$STATE = 0;
							$CONTENT_FOUND = 0;
							$CIFS_FOUND = 0;
						}
					} elsif ( /Adding.*Virtual Server.*Failed/i ) { # Section content needed
						SDP::Core::printDebug(" FAILURE", "$RESOURCE - $_");
						$CONTENT_FOUND = 1;
					}
				} elsif ( /novcifs.*--add/ ) { # Section content needed
					SDP::Core::printDebug(" CONFIRMED", $_);
					$CIFS_FOUND = 1;
					$CIFS_NCS++;
				}
			} elsif ( /^#.*ncs\/(.*)\.load\.out$/ ) { # Section
				$RESOURCE = $1;
				$STATE = 1;
				SDP::Core::printDebug("CHECK", "Section: $_");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: detectCIFSError(): Cannot load file: $FILE_OPEN");
	}
	$RCODE = scalar @VSFAILURES;
	if ( $CIFS_NCS ) {
		if ( $RCODE ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Detected Virtual Server load error, check NFAP attributes for @VSFAILURES");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No 603 errors detected for CIFS NCS Resources");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: detectCIFSError(): NCS CIFS Resource Required, Skipping CIFS Load Test");
	}
	SDP::Core::printDebug("< detectCIFSError", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	detectCIFSError();
SDP::Core::printPatternResults();

exit;

