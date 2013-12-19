#!/usr/bin/perl -w

# Title:       Detect OES2 FCS
# Description: This pattern detects if you are on OES2 FCS and directs you to the TOP 30 "How to upgrade to OES2SP1" TID if you are.
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
#
#  Authors/Contributors:
#   Tregaron Bayly
#   Jason Record (jrecord@suse.com)
#
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
	PROPERTY_NAME_CLASS."=OES",
	PROPERTY_NAME_CATEGORY."=Ugrade",
	PROPERTY_NAME_COMPONENT."=Master TID",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002118"
);

##############################################################################
# Main Program Execution
##############################################################################

use constant NOWS_SBE => 1;
use constant NON_OES2 => 2;
use constant OES2_FCS => 3;
use constant OES2_SP1 => 4;

sub oes2_version {

  my $file = "basic-environment.txt";
  my @output = ();
  my $section = "/etc/novell-release";
  my $oes2 = 0;
  my $fcs = 0;

  if (SDP::Core::getSection($file, $section, \@output)) {
    foreach $_ (@output) {
      if (/Novell Open Enterprise Server 2/) { 
        $oes2 = 1;
      }
      if (/BUILD/) {
        if ($_ =~ "FCS") { $fcs = 1; }
      }
    }
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" in $file - not an OES server?");
  }

  # Check to ensure that we are not running NOWS SBE
  $file = "updates-daemon.txt";
  @output = ();
  $section = "zypp-query-pool products";

  if (SDP::Core::getSection($file, $section, \@output)) {
    foreach $_ (@output) {
      if (/NOWS_SBE/) { return NOWS_SBE; }
    }
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" in $file");
  }

  if ($oes2 == 0) { return NON_OES2; }
  elsif ($oes2 == 1 && $fcs == 1) { return OES2_FCS; }
  else { return OES2_SP1 }

}

SDP::Core::processOptions();
my $oes2_version = oes2_version();
if ($oes2_version == OES2_FCS) {
	SDP::Core::updateStatus(STATUS_RECOMMEND, "OES2 FCS found.  Follow the link for important information on updating to OES2 SP1");
} elsif ($oes2_version == OES2_SP1) {
	SDP::Core::updateStatus(STATUS_ERROR, "OES2 SP1 Found, skipping update test");
} elsif ($oes2_version == NOWS_SBE) {
	SDP::Core::updateStatus(STATUS_ERROR, "NOWS found - updating to OES2 SP1 does not apply");
} else { 
	SDP::Core::updateStatus(STATUS_ERROR, "Host is not running OES2 - scenario does not apply");
}
SDP::Core::printPatternResults();
exit;

