#!/usr/bin/python

# Title:       LUM authentications hung on server
# Description: LUM authentications hung on server with nldapbase package
# Modified:    2014 Sep 10
#
##############################################################################
# Copyright (C) 2014 SUSE LLC
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

import os
import Core
import SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "eDirectory"
META_CATEGORY = "LUM"
META_COMPONENT = "Authentication"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7015635|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=882906"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Main Program Execution
##############################################################################

SERVER = SUSE.getHostInfo()
if( SERVER['OES'] ):
	if( SERVER['OESVersion'] == 11 ):
		if( SERVER['OESPatchLevel'] == 1 or SERVER['OESPatchLevel'] == 2 ):
			RPM_NAME = 'novell-NLDAPbase'
			RPM_VERSION = '8.8.7.4-0.4.6.1'
			if( SUSE.packageInstalled(RPM_NAME) ):
				INSTALLED_VERSION = SUSE.compareRPM(RPM_NAME, RPM_VERSION)
				if( INSTALLED_VERSION < 0 ):
					Core.updateStatus(Core.WARN, "Detected LUM authentication issue, update server to apply fixes")
				else:
					Core.updateStatus(Core.IGNORE, "LUM authentication issue AVOIDED")
			else:
				Core.updateStatus(Core.ERROR, "ERROR: " + RPM_NAME + " not installed")
		else:
			Core.updateStatus(Core.ERROR, "Outside the OES Patch Level Scope")
	else:
		Core.updateStatus(Core.ERROR, "Outside the OES Version Scope")
else:
	Core.updateStatus(Core.ERROR, "Missing OES, Skipping")

Core.printPatternResults()

