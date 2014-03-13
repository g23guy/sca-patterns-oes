#!/usr/bin/python

# Title:       Failed to load novell-named, unknown error
# Description: RootServerInfo zone assignment error
# Modified:    2014 Feb 13
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
#   John Harmon (jharmon@suse.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

import sys, os, Core, SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "DNS"
META_COMPONENT = "Startup"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7014558"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def checkDNSStartFail():
	fileOpen = "dns.txt"
	section = "named.run"
	content = {}
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if "zone 'RootServerInfo.': Designated Server is not available" in content[line]:
				return True
	return False


##############################################################################
# Main Program Execution
##############################################################################

if (SUSE.packageInstalled('novell-bind')):
	if( checkDNSStartFail() ):
		Core.updateStatus(Core.CRIT, "RootServerInfo DNS zone designated primary observed")
	else:
		Core.updateStatus(Core.IGNORE, "RootServerInfo DNS zone correctly missing designated primary")
else:
	Core.updateStatus(Core.ERROR, "ERROR: novell-bind not installed, skipping test")

Core.printPatternResults()
