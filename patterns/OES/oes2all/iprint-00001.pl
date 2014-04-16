#!/usr/bin/perl

# Title:       Frequent segfaults on the iPrint Print Manager
# Description: Servers running the novell-iprint-server RPM dated April 22, 2008 on OES2 servers experience crash/ segfaults every few days. It is suggested to update to an RPM build after this date.
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
#

#  Authors/Contributors:
#   Shaun Price (sprice@novell.com)

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
	PROPERTY_NAME_COMPONENT."=Segfault",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7000747",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=342803"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $IPRINT_RPM='novell-iprint-server';
	my $IPRINT_RPMV='6.0.20080422';

	my $RPM_COMPARED = SDP::SUSE::compareRpm($IPRINT_RPM, $IPRINT_RPMV);
	if ( $RPM_COMPARED == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $IPRINT_RPM Not Installed");
	} elsif ( $RPM_COMPARED > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple $IPRINT_RPM Versions Installed");
	} else {
		if ( $RPM_COMPARED <= 0 ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "iPrint Manager at risk of segfaulting and corrupting the printer database");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "iPrint Manager version appears valid");
		}
	}
SDP::Core::printPatternResults();

exit;


