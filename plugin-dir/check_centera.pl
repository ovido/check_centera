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
use Data::Dumper;

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
my $o_hostname	= undef;	# hostname
my $o_username	= undef;	# username
my $o_password	= undef;	# password
my $o_node		= undef;	# node status
my $o_network	= undef;	# network status
my $o_failures	= undef;	# node status failures
my $o_available	= undef;	# capability availability
my $o_repl		= undef;	# replication status
my $o_script	= undef;	# expect script
my $o_warn		= 10;		# warning
my $o_crit		= 5;		# critical
my @o_type		= ();

my %status		= ( ok => "OK", warning => "WARNING", critical => "CRITICAL", unknown => "UNKNOWN");
my %ERRORS		= ( "OK" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3);

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
	'v+'	=> \$o_verbose,		'verbose+'		=> \$o_verbose,
	'h'		=> \$o_help,		'help'			=> \$o_help,
	'V'		=> \$o_version,		'version'		=> \$o_version,
	'w:s'	=> \$o_warn,		'warning:s'		=> \$o_warn,
	'c:s'	=> \$o_crit,		'critical:s'	=> \$o_crit,
	'H:s'	=> \$o_hostname,	'hostname:s'	=> \$o_hostname,
	'u:s'	=> \$o_username,	'username:s'	=> \$o_username,
	'p:s'	=> \$o_password,	'password:s'	=> \$o_password,
	'j:s'	=> \$o_java,		'java:s'		=> \$o_java,
	'C:s'	=> \$o_cviewer,		'cviewer:s'		=> \$o_cviewer,
	'N'		=> \$o_node,		'node'			=> \$o_node,
	'S'		=> \$o_network,		'network'		=> \$o_network,
	'F'		=> \$o_failures,	'failures'		=> \$o_failures,
	'A'		=> \$o_available,	'available'		=> \$o_available,
	'R'		=> \$o_repl,		'replication'	=> \$o_repl,
	's:s'	=> \$o_script,		'script:s'		=> \$o_script
  );

  # process options
  print_help()		if defined $o_help;
  print_version()	if defined $o_version;

  if (! defined $o_hostname){
  	print "Centera hostname is missing.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  
  if ((! defined $o_node) && (! defined $o_network) && (! defined $o_failures) && (! defined $o_available) && (! defined $o_repl)){
  	print "Missing component to check.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}}
  }
  
  # java and CenteraViewer executable?
  if (! -x $o_java){
  	print "Java binary $o_java isn't executable.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  if (! -x $o_cviewer){
  	print "CenteraViewer $o_cviewer isn't executable.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  
  # username and password given?
  if ((! defined $o_username) || (! defined $o_password)){
  	print "Missing username or password.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  if (! defined $o_script){
  	print "Expect script missing.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  if (! -r $o_script){
  	print "Expect script $o_script not readable.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  
  # delete non-digit chars from warning and critical like %
  $o_warn =~ s/\D//g;
  $o_crit =~ s/\D//g;
  if ($o_warn <= 0 || $o_warn >= 100){
  	print "Warning value ($o_warn) must be between 0% and 100%.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }
  if ($o_crit <= 0 || $o_crit >= 100){
  	print "Critical value ($o_crit) must be between 0% and 100%.\n";
  	print_usage();
  	exit $ERRORS{$status{'unknown'}};
  }

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
  print "        -N | -S | -F | -A | -R [-w <warning>] [-c <critical>] -s <script>\n";
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
 -s, --script
    Expect script for CenteraViewer
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

# What do we want to check?
# Node status
if (defined $o_node){
  my $output = check_status("node");
  exit_plugin($statuscode,$output);
}

# Network status
if (defined $o_network){
  my $output = check_status("network");
  exit_plugin($statuscode,$output);
}

# Available capacity
if (defined $o_available){
  my $output = check_capacity();
  exit_plugin($statuscode,$output);
}

# Replication check
if (defined $o_repl){
  my $output = check_repl();
  exit_plugin($statuscode,$output);
}

# Node failures
if (defined $o_failures){
  my $output = check_failures();
  exit_plugin($statuscode,$output);
}


#***************************************************#
#  Function: check_status                           #
#---------------------------------------------------#
#  Check status of nodes and networks.              #
#  ARG1: component (node, network)                  #
#                                                   #
#***************************************************#

sub check_status{

  my $component = $_[0];	
  my $output = "";
  
  # call CenteraViewer.jar binary
  my $rref = exec_centeraviewer(); 
  my @return = @{ $rref };

  for (my $i=0;$i<=$#return;$i++){
  	# skip all lines except lines startig with cabinet number
  	next unless $return[$i] =~ m/^[0-9]/;
  	$return[$i] =~ s/\s+/ /g;
  	#print $return[$i] . "\n";
  	# example output (Nodes)
  	# 2        c002n01 A,M,R,S         g4LP                    ATS   on                eth2:connected
    # 2        c002n05 M,S             g4LP                    ATS   on                eth2:connected
    # 2        c002n07 S               g4LP                    ATS   on
    # example output (Network)
    # 2        c002sw0   1     on
    # 2        c002sw1   0     on

  	# get statistics
  	my @tmp = split / /, $return[$i];
  	
  	if ($component eq "node"){
  	  # get host status
  	  if ($tmp[5] ne "on"){
  	    $output .= "Node $tmp[1] is $tmp[5], ";
  	    $statuscode = "critical";	
  	  }
  	  # get failures
  	  if ( ($tmp[2] =~ m/A/) || ($tmp[2] =~ m/M/) ){
  	  	my $size = scalar @tmp - 6;
  	    if ($tmp[$#tmp] !~ m/\:connected$/){
  	  	  $output .= "Node $tmp[1] failures ";
  	  	  for (my $x=6;$x<=$#tmp;$x++){
  	  	  	$output .= $tmp[$x];
  	  	  }
  	  	  $output .= ", ";
  	  	  $statuscode = "critical";
  	    }
  	  }
  	}else{
  	  # get network status
  	  if ($tmp[3] ne "on"){
  	  	$output .= "Switch $tmp[1] is $tmp[3], ";
  	  	$statuscode = "critical";
  	  }	
  	}
  }
  
  if ($output eq ""){
    $output = "All " . $component . "s with status on";
  	$statuscode = "ok" if ($statuscode ne "warning" || $statuscode ne "critical");
  }else{
  	# remove trailing ", "
  	chop $output;
  	chop $output;
  }
  
  return $output;
  
}


#***************************************************#
#  Function: check_capacity                         #
#---------------------------------------------------#
#  Check available capacity.                        #
#                                                   #
#***************************************************#

sub check_capacity{
  my $output = "";
  
  # call CenteraViewer.jar binary
  my $rref = exec_centeraviewer(); 
  my @return = @{ $rref };

  for (my $i=0;$i<=$#return;$i++){
  	# skip all lines except line startig with System Buffer
  	next unless $return[$i] =~ m/^System\s{1}Buffer:/;
  	$return[$i] =~ s/\s+/ /g;
  	#print $return[$i] . "\n";
  	# example output
    # Available Capacity:                     33 TB   (37%)

  	# get statistics
  	my @tmp = split / /, $return[$i];
  	$tmp[4] =~ s/\D//g;
	$output = "Available Capacity ($tmp[4]%)";
	# apped performance data
	if ($perfdata == 1){
	  $output .= "|'capacity'=$tmp[4]%;$o_warn;$o_crit;;"
	}
  	if ($o_crit >= $tmp[4]){
  	  $statuscode = "critical";
  	}elsif ($o_warn >= $tmp[4]){
  	  $statuscode = "warning";
  	}else{
  	  $statuscode = "ok";
  	}
  	
  }
  return $output;	
}


#***************************************************#
#  Function: check_repl                             #
#---------------------------------------------------#
#  Check replication status.                        #
#                                                   #
#***************************************************#

sub check_repl{
  my $output = "";	
	 
  # call CenteraViewer.jar binary
  my $rref = exec_centeraviewer(); 
  my @return = @{ $rref };

  for (my $i=0;$i<=$#return;$i++){
  	# skip all lines except line startig with Replication Enabled/Paused
  	next unless $return[$i] =~ m/^Replication/;
  	$return[$i] =~ s/\s+/ /g;
  	#print $return[$i] . "\n";
  	# example output
    # Replication Enabled:                          Mittwoch, 25. Jänner 2006 16:33:41 MEZ
    # Replication Paused:                           no

  	# get statistics
  	my @tmp = split / /, $return[$i];
  	if ($tmp[1] eq "Enabled:"){
  	  $output .= "Replication enabled on ";
  	  for (my $x=2;$x<=$#tmp;$x++){
  	  	$output .= $tmp[$x] . " ";
  	  }
  	  chop $output;
  	  $output .= "; ";
  	}elsif ($tmp[1] eq "Paused:"){
  	  if ($tmp[2] ne "no"){
  	  	$statuscode = "critical";
  	  	$output .= "Replication paused ($tmp[2]).";
  	  }else{
  	    $statuscode = "ok";
  	  }
  	}
  	
  }
  return $output;	
}


#***************************************************#
#  Function: check_failures                         #
#---------------------------------------------------#
#  Check node status failures.                      #
#                                                   #
#***************************************************#

sub check_failures{
  my $output = "";
  
  # call CenteraViewer.jar binary
  my $rref = exec_centeraviewer(); 
  my @return = @{ $rref };

  for (my $i=0;$i<=$#return;$i++){
  	if ($return[$i] eq "No node is found in the specified scope"){
  	  # Node node failures
  	  $statuscode = "ok";
  	  $output = "No node failures found.";
  	}
  }
  # Output of nodes with failures isn't known, yet
  if ($statuscode ne "ok"){
  	$statuscode = "critical";
  	$output = "Node failures found.";
  }
  return $output;	
}


#***************************************************#
#  Function: exec_centeraviewer                     #
#---------------------------------------------------#
#  Execute CenteraViewer binary and return output.  #
#                                                   #
#***************************************************#

sub exec_centeraviewer{
  my @result;
#  open (CVIEWER, "$o_java -cp $o_cviewer com.filepool.remote.cli.CLI -u $o_username -p $o_password -ip $o_hostname -script $o_script |");
# use fake binary for testing
  open (CVIEWER, "cat $o_script | /usr/local/bin/CenteraViewer.jar |");
  while (<CVIEWER>){
  	chomp $_;
  	push @result, $_;
  }
  close CVIEWER;
  return \@result;
}


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
