#!/usr/bin/python

# Title:       "CASAcli -l" returns "Found 0 credential sets" after update
# Description: After applying glibc-2.11.3-17.62.1 CASA credentials go missing
# Modified:    2014 Jul 24
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
#   Rance Burker (rtburker@suse.com)
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
META_CATEGORY = "CASA"
META_COMPONENT = "CASA"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7015222|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=883217"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def missingCASACredentials():
	fileOpen = "env.txt"
	section = 'CASAcli -l'
	content = {}
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if "Found 0 credential set" in content[line]:
				return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

PACKAGE_NAME = 'glibc'
BROKE_VERSION = '2.11.3-17.62.1'
FIXED_VERSION = '2.11.3-17.66.1'

if( SUSE.packageInstalled(PACKAGE_NAME) ):
	INFO = SUSE.getRpmInfo(PACKAGE_NAME)
	if( INFO['version'] == BROKE_VERSION and FIXED_VERSION > INFO['version']):
		if( missingCASACredentials() ):
			Core.updateStatus(Core.CRIT, "CASA credentials missing")
		else:
			Core.updateStatus(Core.IGNORE, "CASA credentials present")
	else:
		Core.updateStatus(Core.IGNORE, "Valid version installed, issue fixed")
else:
	Core.updateStatus(Core.ERROR, "Package not installed, abort test")

Core.printPatternResults()

