#!/usr/bin/python

# Title:       DSfW NETLOGON failed to authenticate
# Description: Workstation fails to login after November 2013 Maint Patch
# Modified:    2014 Feb 05
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

import os
import Core
import SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "OES"
META_CATEGORY = "DSfW"
META_COMPONENT = "XAD"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7014322|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=836970|META_LINK_Script=http://dsfwdude.com/downloads/update_computer_acls.tgz"
Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def failedauth0xc0000022():
	fileOpen = "messages.txt"
	section = '/var/log/messages'
	content = {}
	if Core.getSection(fileOpen, section, content):
		C1 = 0
		C2 = 0
		C3 = 0
		for line in content:
			if "failed to authenticate: 0xc0000022" in content[line]:
				C1 = 1
			elif "opened secure channel" in content[line]:
				C2 = 1
			elif "NetrLogonGetDomainInfo: Insufficient access" in content[line]:
				C3 = 1
			ALL = C1+C2+C3
#			print "C1, C2, C3, ALL = " + str(C1) + ", " + str(C2) + ", " + str(C3) + ": " + str(ALL)
			if ( ALL > 2 ):
				return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

PACKAGE = 'novell-xad-framework'
FIXED_BEFORE = '2.4.6553-0.3.4'
FIXED_AFTER = '2.4.6723-0.3.11'

if( SUSE.packageInstalled(PACKAGE) ):
	INFO = SUSE.getRpmInfo(PACKAGE)
#	print "INFO = " + str(INFO)
	if( FIXED_BEFORE < INFO['version'] and INFO['version'] <= FIXED_AFTER ):
		if( failedauth0xc0000022() ):
			Core.updateStatus(Core.CRIT, "Workstations ACL has not been updated")
		else:
			Core.updateStatus(Core.IGNORE, "No failed auth 0xc0000022 errors found")
	else:
		Core.updateStatus(Core.IGNORE, "Valid version installed, issue fixed")
else:
	Core.updateStatus(Core.ERROR, "Package not installed, aborting test")

Core.printPatternResults()

