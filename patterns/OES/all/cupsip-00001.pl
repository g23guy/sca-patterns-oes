#!/usr/bin/perl

# Title:       Cups and iPrint Port Conflict
# Description: Cups will conflict with iPrint on an OES server
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
	PROPERTY_NAME_COMPONENT."=Conflict",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3827959"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::packageInstalled('novell-iprint-server') ) {
		my %CUPS = SDP::SUSE::getServiceInfo('cups');
		my %IPRINT = SDP::SUSE::getServiceInfo('novell-ipsmd');
		if ( $CUPS{'runlevelstatus'} > 0 ) { # cups on at boot
			if ( $IPRINT{'runlevelstatus'} > 0 ) { # iprint on at boot
				if ( $CUPS{'running'} > 0 ) { # cups is currently running
					SDP::Core::updateStatus(STATUS_CRITICAL, "iPrint/Cups port conflict detected, turn cups off");
				} else {
					SDP::Core::updateStatus(STATUS_WARNING, "Potential iPrint/Cups port conflict, turn cups off before rebooting");
				}
			} else { # iprint off at boot
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Novell iPrint off at boot, cups on at boot");
			}
		} else { # cups off at boot
			if ( $IPRINT{'runlevelstatus'} > 0 ) { # iprint on at boot
				if ( $CUPS{'running'} > 0 ) { # cups is currently running
					SDP::Core::updateStatus(STATUS_CRITICAL, "iPrint/Cups port conflict detected, stop the cups process");
				} else {
					if ( $IPRINT{'running'} > 0 ) { # iprint running
						SDP::Core::updateStatus(STATUS_ERROR, "iPrint running, no cups port conflict detected");
					} else {
						SDP::Core::updateStatus(STATUS_ERROR, "iPrint NOT running, but no cups port conflict detected");
					}
				}
			} else { # iprint off at boot
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Novell iPrint off at boot, cups off at boot");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "iPrint not installed, skipping port conflict test");
	}
SDP::Core::printPatternResults();

exit;

