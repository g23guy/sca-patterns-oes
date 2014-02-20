 #!/usr/bin/python

# Title:       eDir patch core dumps in LDAP
# Description: NDSD cores in LDAP after upgrading to eDirectory 8.8 SP8 Patch 1 or 8.8 SP7 Patch 5
# Modified:    2014 Feb 20
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
META_CATEGORY = "eDirectory"
META_COMPONENT = "Crash"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=http://www.novell.com/support/kb/doc.php?id=7014591|META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=864542"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Main Program Execution
##############################################################################

RPM_NAME = 'novell-NDSserv'
RPM_VERSION = '8.8.7.5-0.3.2'
if( SUSE.packageInstalled(RPM_NAME) ):
	INSTALLED_VERSION = SUSE.compareRPM(RPM_NAME, RPM_VERSION)
	if( INSTALLED_VERSION == 0 ):
		Core.updateStatus(Core.CRIT, "eDirectory susceptible to core dump from LDAP lookups, update server")
	else:
		Core.updateStatus(Core.IGNORE, "Bug fixes applied for ndsd core dump in ldap")
else:
	Core.updateStatus(Core.ERROR, "ERROR: " + RPM_NAME + " not installed")

Core.printPatternResults()

