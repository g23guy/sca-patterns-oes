#!/usr/bin/perl

# Title:       Samba without eDirectory
# Description: novell-samba and Secure LDAP On OES Linux Without A Local Copy Of eDirectory
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
	PROPERTY_NAME_CATEGORY."=Samba",
	PROPERTY_NAME_COMPONENT."=Login",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011753"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub sambaRemoteEdir {
	SDP::Core::printDebug('> sambaRemoteEdir', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'samba.txt';
	my $SECTION = '/etc/samba/smb.conf';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^\s*passdb backend.*NDS_ldapsam:ldap/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: sambaRemoteEdir(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< sambaRemoteEdir", "Returns: $RCODE");
	return $RCODE;
}


sub tlsReqCertAllow {
	SDP::Core::printDebug('> tlsReqCertAllow', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ldap.txt';
	my $SECTION = '/etc/openldap/ldap.conf';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^TLS_REQCERT.*allow/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: tlsReqCertAllow(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< tlsReqCertAllow", "Returns: $RCODE");
	return $RCODE;
}

sub smbldapError {
	SDP::Core::printDebug('> smbldapError', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'samba.txt';
	my $SECTION = '/var/log/samba/log.smbd';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /failed to bind to server ldap.*Error.*Can't contact LDAP server/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: smbldapError(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< smbldapError", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $PKG_NAME_EDIR = 'novell-NDSserv';
if ( sambaRemoteEdir() ) {
	if ( SDP::SUSE::packageInstalled($PKG_NAME_EDIR) ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: eDirectory installed, skipping samba test");
	} else {
		if ( tlsReqCertAllow() ) {
			SDP::Core::updateStatus(STATUS_ERROR, "TLS_REQCERT set correctly");
		} else {
			if ( smbldapError() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "LUM and Samba enabled user authentication failure, set TLS_REQCERT allow");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "LUM and Samba enabled user authentication failure probable, set TLS_REQCERT allow");
			}
		}
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "No Samba LDAPS connection to eDirectory");
}
SDP::Core::printPatternResults();
exit;


