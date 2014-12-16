#!/usr/bin/python

# Title:       DSfW Crashes Frequently
# Description: DSfW: Domain Services for Windows Daemon crashes frequently
# Modified:    2014 Dec 16
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
import oes
import SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "DSfW"
META_COMPONENT = "Crash"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7015998|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=894284"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def maintPatchInstalled():
	fileOpen = "updates.txt"
	section = "/usr/bin/zypper.*patches"
	patch = re.compile("Dec.*2014.*Scheduled.*Maintenance", re.IGNORECASE)
	content = {}
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if patch.search(content[line]):
				return True
	return False

def errorsFound():
	fileOpen = "messages.txt"
	section = "/var/log/messages"
	errmsg = re.compile("xadsd.*segfault.*in libdcerpc\.so", re.IGNORECASE)
	content = {}
	if Core.getSection(fileOpen, section, content):
		for line in content:
			if errmsg.search(content[line]):
				return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

PACKAGE = "novell-xad-framework"
if( oes.dsfwCapable() and SUSE.packageInstalled(PACKAGE) ):
	if( maintPatchInstalled() ):
		Core.updateStatus(Core.IGNORE, "December 2014 Maintenance Patch installed, AVOIDED")
	else:
		if( errorsFound() ):
			Core.updateStatus(Core.CRIT, "DSfW has crashed due to a known issue, update system with latest patches to resolve")
		else:
			Core.updateStatus(Core.WARN, "DSfW may be susceptible to crashing, update to lastest patches to avoid")
else:
	Core.updateStatus(Core.ERROR, "ERROR: Not a DSfW server")

Core.printPatternResults()

