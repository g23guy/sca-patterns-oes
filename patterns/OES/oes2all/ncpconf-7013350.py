#!/usr/bin/python

# Title:       NSS trustees missing on reboot
# Description: ncpcon nss resync=VOLUME-NAME FAILED completion
# Modified:    2014 Mar 24
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

import sys, os, Core, SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "NSS"
META_COMPONENT = "Trustees"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7013350"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def getInvalidNSSVolumes():
	fileOpen = "novell-ncp.txt"
	section = "ncpserv.conf"
	content = {}
	VOLS = []
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if content[line].startswith("VOLUME"):
				if "/media/nss" in content[line]:
					LINE_LIST = content[line].split()
					VOLS.append(LINE_LIST[1])
	return VOLS

##############################################################################
# Main Program Execution
##############################################################################

BAD_VOLS = getInvalidNSSVolumes()
if( len(BAD_VOLS) > 0 ):
	VOLUMES = ", ".join(BAD_VOLS)
	Core.updateStatus(Core.CRIT, "Invalid NCP Server Configuration, detected NSS Volumes: " + str(VOLUMES))
else:
	Core.updateStatus(Core.IGNORE, "Valid NCP Configuration, not applicable")

Core.printPatternResults()

