#!/usr/bin/python

# Title:       NCS Volume Lock
# Description: Can't get lock for logical volume group
# Modified:    2015 Aug 26
#
##############################################################################
# Copyright (C) 2015 SUSE LINUX Products GmbH, Nuernberg, Germany
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
import oes

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "NCS"
META_CATEGORY = "LVM"
META_COMPONENT = "Locks"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7016788"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def clusterRequestFailure():
	fileOpen = "lvm.txt"
	section = "/vgs"
	content = []
	IN_STATE = False
	if Core.getRegExSection(fileOpen, section, content):
		for line in content:
			if( IN_STATE ):
				if "Can't get lock for" in line:
					return True
			elif "cluster request failed" in line:
				IN_STATE = True
	return False

##############################################################################
# Main Program Execution
##############################################################################

if( oes.ncsActive() ):
	if( clusterRequestFailure() ):
		Core.updateStatus(Core.CRIT, "Cluster request failure, cannot get LVM lock -- consider a cluster restart")
	else:
		Core.updateStatus(Core.IGNORE, "No cluster request failure detected")
else:
	Core.updateStatus(Core.ERROR, "ERROR: Applies only to active NCS clusters")

Core.printPatternResults()


