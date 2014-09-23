#!/usr/bin/python

# Title:       slurpfile buffer overflow
# Description: OES11 SP2 server spawns a "slurpfile() read() buffer overflow on file /proc/stat" message every 20 seconds
# Modified:    2014 Sep 23
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
import re

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "Ganglia"
META_COMPONENT = "Overflow"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7015651|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=875846|META_LINK_GangliaBUG=http://bugzilla.ganglia.info/cgi-bin/bugzilla/show_bug.cgi?id=298"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def errorsFound():
	fileOpen = "messages.txt"
	section = "/var/log/messages"
	content = {}
	OVERFLOW = re.compile("gmond.*slurpfile.*read.*buffer overflow on file /proc/stat", re.IGNORECASE)
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if OVERFLOW.search(content[line]):
#				print content[line]
				return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

SERVER = SUSE.getHostInfo()
if( SERVER['OES'] ):
	if( SERVER['OESVersion'] == 11 ):
		if( SERVER['OESPatchLevel'] == 1 or SERVER['OESPatchLevel'] == 2 ):
			RPM_NAME = 'novell-ganglia-monitor-core-gmond'
			if( SUSE.packageInstalled(RPM_NAME) ):
				PATCH = SUSE.PatchInfo('August-2014-Scheduled-Maintenance')
#				PATCH.debugPatchDisplay()
				if( PATCH.valid ):
					if( not PATCH.installed ):
						if( errorsFound() ):
							Core.updateStatus(Core.CRIT, "Detected Ganglia slurpfile buffer overflow messages, update server to apply fixes")
						else:
							Core.updateStatus(Core.WARN, "Susceptible to Ganglia slurpfile buffer overflow messages, update server to apply fixes")
					else:
						Core.updateStatus(Core.IGNORE, "Ganglia fixes are not needed, issue AVOIDED")
				else:
					Core.updateStatus(Core.ERROR, "ERROR: Invalid patch updates.txt section")
			else:
				Core.updateStatus(Core.ERROR, "ERROR: Package not installed: " + RPM_NAME)
		else:
			Core.updateStatus(Core.ERROR, "ERROR: Outside OES Version Scope")
	else:
		Core.updateStatus(Core.ERROR, "ERROR: Outside OES Patch Level Scope")
else:
	Core.updateStatus(Core.ERROR, "ERROR: OES Not Installed, skipping Ganglia test")

Core.printPatternResults()


