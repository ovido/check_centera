#!/usr/bin/perl -w
# nagios: -epn

#######################################################
#                                                     #
#  Name:    check_centera                             #
#                                                     #
#  Version: 0.1                                       #
#  Created: 2013-05-10                                #
#  License: GPL - http://www.gnu.org/licenses         #
#  Copyright: (c)2013 ovido gmbh, http://www.ovido.at #
#  Author:  Rene Koch <r.koch@ovido.at>               #
#  Credits: s IT Solutions AT Spardat GmbH            #
#  URL: https://labs.ovido.at/monitoring              #
#                                                     #
#######################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Changelog:
# * 0.1.0 - Fri May 10 2013 - Rene Koch <r.koch@ovido.at>
# - This is the first public beta release of new plugin check_centera

use strict;
use Getopt::Long;

# Configuration
my $o_java		= "/usr/bin/java";
my $o_cviewer	= "/usr/local/bin/CenteraViewer\.jar";

# create performance data
# 0 ... disabled
# 1 ... enabled
my $perfdata	= 1;

# Variables
my $prog	= "check_centera";
my $version	= "0.1";
my $projecturl  = "https://labs.ovido.at/monitoring/wiki/check_centera";

my $o_verbose	= undef;	# verbosity
my $o_help		= undef;	# help
my $o_version	= undef;	# version
my @o_warn	= ();		# warning
my @o_crit	= ();		# critical
my @o_type	= ();

my %status	= ( ok => "OK", warning => "WARNING", critical => "CRITICAL", unknown => "UNKNOWN");
my %ERRORS	= ( "OK" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3);

my $statuscode	= "unknown";
my $statustext	= "";
my $perfstats	= "|";


#***************************************************#
#  Function: parse_options                          #
#---------------------------------------------------#
#  parse command line parameters                    #
#                                                   #
#***************************************************#
sub parse_options(){
  Getopt::Long::Configure ("bundling");
  GetOptions(
	'v+'	=> \$o_verbose,		'verbose+'	=> \$o_verbose,
	'h'		=> \$o_help,		'help'		=> \$o_help,
	'V'		=> \$o_version,		'version'	=> \$o_version,
	'w:s'	=> \@o_warn,		'warning:s'	=> \@o_warn,
	'c:s'	=> \@o_crit,		'critical:s'	=> \@o_crit
  );

  # process options
  print_help()		if defined $o_help;
  print_version()	if defined $o_version;



  # verbose handling
  $o_verbose = 0 if ! defined $o_verbose;

}


#***************************************************#
#  Function: print_usage                            #
#---------------------------------------------------#
#  print usage information                          #
#                                                   #
#***************************************************#
sub print_usage(){
  print "Usage: $0 [-v] -H <hostname> -u <user> -p <password> [-j <java>] [-C <centera-viewer> \n";
  print "        -N | -S | -F | -A | -R [-w <warning>] [-c <critical>]\n";
}


#***************************************************#
#  Function: print_help                             #
#---------------------------------------------------#
#  print help text                                  #
#                                                   #
#***************************************************#
sub print_help(){
  print "\nCentera checks for Icinga/Nagios version $version\n";
  print "GPL license, (c)2013 - Rene Koch <r.koch\@ovido.at>\n\n";
  print_usage();
  print <<EOT;

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -H, --hostname=HOSTNAME
    Host name or IP Address of EMC Centera storage
 -u, --username=USERNAME
    Username required for CenteraViewer.jar
 -p, --password=PASSWORD
    Password required for CenteraViewer.jar
 -j, --java=PATH
    Path to java binary (default: $o_java)
 -C, --cviewer=PATH
    Path to CenterViewer.jar (default: $o_cviewer)
 -N, --node
    Check node status
 -S, --network
    Check network status
 -F, --failures
    Check node status failures
 -A, --available
    Check capability availability
 -R, --replication
    Check Replication status
 -w, --warning=DOUBLE
    Value to result in warning status (ms)
 -c, --critical=DOUBLE
    Value to result in critical status (ms)
 -v, --verbose
    Show details for command-line debugging
    (Icinga/Nagios may truncate output)

Send email to r.koch\@ovido.at if you have questions regarding use
of this software. To submit patches of suggest improvements, send
email to r.koch\@ovido.at
EOT

exit $ERRORS{$status{'unknown'}};
}



#***************************************************#
#  Function: print_version                          #
#---------------------------------------------------#
#  Display version of plugin and exit.              #
#                                                   #
#***************************************************#

sub print_version{
  print "$prog $version\n";
  exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function: main                                   #
#---------------------------------------------------#
#  The main program starts here.                    #
#                                                   #
#***************************************************#

# parse command line options
parse_options();


#***************************************************#
#  Function exit_plugin                             #
#---------------------------------------------------#
#  Prints plugin output and exits with exit code.   #
#  ARG1: status code (ok|warning|cirtical|unknown)  #
#  ARG2: additional information                     #
#***************************************************#

sub exit_plugin{
  print "Centera $status{$_[0]}: $_[1]\n";
  exit $ERRORS{$status{$_[0]}};
}


exit $ERRORS{$status{'unknown'}};



