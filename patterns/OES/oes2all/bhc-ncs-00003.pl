#!/usr/bin/perl

# Title:       Novell Cluster Services Basic Service Pattern
# Description: Checks to see if Novell Cluster Services (NCS) is installed, valid and running
# Modified:    2014 Jan 28

##############################################################################
#  Copyright (C) 2013,2014 SUSE LLC
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
	PROPERTY_NAME_CLASS."=Basic Health",
	PROPERTY_NAME_CATEGORY."=OES",
	PROPERTY_NAME_COMPONENT."=NCS",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7001417"
);

##############################################################################
# Program execution functions
##############################################################################

SDP::Core::processOptions();

	my $CHECK_PACKAGE = "novell-cluster-services";
	my $CHECK_SERVICE = "novell-ncs";
	my $FILE_SERVICE = "novell-ncs.txt";
	my %HOST_INFO = SDP::SUSE::getHostInfo();

	if ( $HOST_INFO{'oes'} ) {
		if ( packageInstalled($CHECK_PACKAGE) ) {
			SDP::SUSE::serviceHealth($FILE_SERVICE, $CHECK_PACKAGE, $CHECK_SERVICE);
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Basic Service Health; Package Not Installed: $CHECK_PACKAGE");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Outside Product Scope, Requires OES to be installed");
	}
SDP::Core::printPatternResults();
exit;

