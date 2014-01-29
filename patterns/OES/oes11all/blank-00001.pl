#!/usr/bin/perl

# Title:       Empty NCS unload or load scripts
# Description: Empty un/load scripts will cause cluster issues.
# Modified:    2013 Jun 20

##############################################################################
#  Copyright (C) 2013 SUSE LLC
##############################################################################
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)

##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=NCS",
	PROPERTY_NAME_CATEGORY."=Script",
	PROPERTY_NAME_COMPONENT."=Validation",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7006781"
);

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
my $FILE_NCS = 'novell-ncs.txt';
my @NCSDATA = ();
my $CHECK_SCRIPT = 0;
my $SCRIPT = '';
my $FOUND = 0;
my @EMPTY_SCRIPTS = ();
my @EMPTY_TEMPLATES = ();
my %NCS_TEMPLATES = ();
my $NEXT = 0;
my $TEMPLATE_NAME = '';
# This pattern requires the ncsldapCheck.py section come before all (un)load script sections in the novell-ncs.txt file.
# If no ncsldapCheck.py section is found, all empty scripts are elevated to critical, because templates cannot be identified 
#  separately. 
if ( SDP::SUSE::packageInstalled('novell-cluster-services') ) {
	if ( SDP::Core::loadFile($FILE_NCS, \@NCSDATA) ) {
		foreach $_ (@NCSDATA) {
			if ( $NEXT ) { # determines if the resource found is a template
				if ( m/nCSResourceTemplate/ ) {
					SDP::Core::printDebug("  main TEMPLATE", $TEMPLATE_NAME);
					$NCS_TEMPLATES{$TEMPLATE_NAME} = 1;
				} else {
					SDP::Core::printDebug("  main RESOURCE", $TEMPLATE_NAME);
				}
				$NEXT = 0;
			} elsif ( $CHECK_SCRIPT ) { # evaluates (un)load scripts
				if ( /^#==\[/ ) { # I reached the end of the (un)load script
					if ( $FOUND ) {
						$CHECK_SCRIPT = 0; # Move to the next (un)load script, this one was NOT empty
					} else {
						my @TSCRIPT = split(/\/|\./, $SCRIPT);
						pop(@TSCRIPT);
						my $RESOURCE = $TSCRIPT[$#TSCRIPT];
						if ( $NCS_TEMPLATES{$RESOURCE} ) {
							SDP::Core::printDebug("  main EMPTY", "Push Template: $RESOURCE");
							push(@EMPTY_TEMPLATES, $SCRIPT);
						} else {
							SDP::Core::printDebug("  main EMPTY", "Push Resource: $RESOURCE");
							push(@EMPTY_SCRIPTS, $SCRIPT); 
						}
					}
				} elsif ( /\S/ ) { # found a non-white space character, the template is NOT empty, but "FOUND".
					$FOUND = 1;
				}
			} elsif ( m/Resource\/template name: (.*)/i ) { # finds a resource
				$TEMPLATE_NAME = $1;
				$NEXT = 1;
			} elsif ( m/^#\s*(.*)\.load$/ ) { # finds a load script
				SDP::Core::printDebug("  main LOAD", $_);
				$SCRIPT = "$1.load";
				$CHECK_SCRIPT = 1;
				$FOUND = 0;
			} elsif ( m/^#\s*(.*)\.unload$/ ) { # finds an unload script
				SDP::Core::printDebug("  main UNLOAD", $_);
				$SCRIPT = "$1.unload";
				$CHECK_SCRIPT = 1;
				$FOUND = 0;
			}
		}
		my $EMPTY_SCRIPTS_FOUND = scalar @EMPTY_SCRIPTS;
		my $EMPTY_TEMPLATES_FOUND = scalar @EMPTY_TEMPLATES;
		if ( $EMPTY_SCRIPTS_FOUND ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Empty (un)load scripts found: @EMPTY_SCRIPTS");
		} elsif ( $EMPTY_TEMPLATES_FOUND ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Empty (un)load template scripts found: @EMPTY_TEMPLATES");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No empty (un)load scripts found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing or empty file: $FILE_NCS");
	}
} else {
	SDP::Core::updateStatus(STATUS_ERROR, "ERROR: NCS not installed, skipping (un)load script test");
}	
SDP::Core::printPatternResults();
exit;

