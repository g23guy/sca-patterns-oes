#!/usr/bin/python

# Title:       sfcb SSL failure
# Description: iManager storage management reports file protocol error after applying java-1_6_0-ibm-1.6.0_sr16.2-0.3.1 (patch 9992)
# Modified:    2014 Dec 17
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

import re
import os
import Core
import SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "SFCB"
META_COMPONENT = "SSL"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7015980|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=908537"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def javaPatchApplied():
	RPM_NAME = 'java-1_6_0-ibm'
	RPM_VERSION = '1.6.0_sr16.1-0.3.1'
	if( SUSE.packageInstalled(RPM_NAME) ):
		INSTALLED_VERSION = SUSE.compareRPM(RPM_NAME, RPM_VERSION)
		if( INSTALLED_VERSION >= 0 ):
			return True
	return False

def hotPatchApplied():
	return SUSE.PatchInfo('December-2014-Hot-Patch').installed

def errorFound():
	fileOpen = "messages.txt"
	section = "/var/log/messages"
	content = {}
	errmsg = re.compile("sfcb.*httpAdapter.*Error accepting SSL connection -- exiting", re.IGNORECASE)
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if errmsg.search(content[line]):
				return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

SFCB = SUSE.getServiceInfo('sfcb')
#print str(SFCB)
if( SFCB['OnForRunLevel'] ):
	if( javaPatchApplied() ):
		if( hotPatchApplied() ):
			Core.updateStatus(Core.IGNORE, "Hot patch applied for SFCB SSL, AVOIDED")
		else:
			if( errorFound() ):
				Core.updateStatus(Core.CRIT, "Detected iManager storage plugin failure")
			else:
				Core.updateStatus(Core.WARN, "Detected possible iManager storage plugin failure")
	else:
		Core.updateStatus(Core.ERROR, "Affected Java patch not installed, not applicable")
else:
	Core.updateStatus(Core.ERROR, "SFCB Service disabled, not applicable")

Core.printPatternResults()


