#!/usr/bin/perl -w
#
# @File check_iprinters.pl
# @Author dbenjamin
# @Created Aug 4, 2015 2:59:02 PM
# Licence : GPL - http://www.gnu.org/licenses/lgpl-3.0.html
#

use strict;
use LWP::Simple;
use HTML::TreeBuilder;
use Getopt::Long;
my $nagios_plugins_utils =
  "/usr/lib/nagios/plugins/utils.pm";    #used to test for the library
die "\nLooking for nagios utils.pm at $nagios_plugins_utils"
  unless ( -e $nagios_plugins_utils );
use lib "/usr/lib/nagios/plugins";       #use just the path here
use utils qw(%ERRORS $TIMEOUT);

my ( $opt_h, $opt_I, $opt_Q, $opt_v, $opt_P, $opt_V );
my ( $printer_state, $accepting_jobs, $jobs_scheduled );
my $i = 0;                               #iteration holder
$opt_P = '631';

alarm($TIMEOUT);

sub print_version {
    print "File:     check_iprinters.pl\n";
    print "Author:   dbenjamin\n";
    print "Created:  Aug 4, 2015\n";
    print "Release:  0.0.1\n";
    print "Tested against Novell iPrint Server 6.7.0.20150629-0.6.6, ";
    print "running on SLES 11, SP3 with OES 11, SP2.\n";
    exit $ERRORS{'UNKNOWN'};
}

sub print_exit {
    print
"Usage: $0 -I <host address> -Q <queue name> [-P <port> default=631] [-v enable verbose] [--version]\n\n";
    exit $ERRORS{'UNKNOWN'};
}

sub print_verbose {
    print "Printer State:  $printer_state\n";
    print "Printer is Accepting Jobs:  $accepting_jobs\n";
    print "Jobs Scheduled:  $jobs_scheduled\n";
}

GetOptions(
    "version" => \$opt_V,
    "h"       => \$opt_h,
    "help"    => \$opt_h,
    "I=s"     => \$opt_I,
    "Q=s"     => \$opt_Q,
    "P:s"     => \$opt_P,
    "v"       => \$opt_v,
) or print_exit;

if ($opt_V) {
    print_version;
}

if ($opt_h) {
    print_exit;
}

if ( !$opt_I ) {
    print "No Host address specified\n";
    print_exit;
}
if ( !$opt_Q ) {
    print "No Queue name specified\n";
    print_exit;
}

if ( ( $opt_I eq '' ) or ( $opt_Q eq '' ) ) { print_exit; }
my $tree   = new HTML::TreeBuilder->new;
my $url    = "http://$opt_I:$opt_P/ipp/$opt_Q";
my $result = get($url);
die "\nCouldn't get $url" unless defined $result;
$tree->parse($result);
my @tbrows = $tree->look_down( '_tag', 'TR' );
die "No response, check the URL for errors:  $url\n\n" unless @tbrows;
foreach $i ( 2 .. 4 ) {
    my @td = $tbrows[$i]->look_down( '_tag', 'TD' );
    if ( $i == 2 ) { $printer_state  = $td[1]->as_text; }
    if ( $i == 3 ) { $accepting_jobs = $td[1]->as_text; }
    if ( $i == 4 ) { $jobs_scheduled = $td[1]->as_text; }
}
if ( ( $printer_state =~ /error/i ) & ( $printer_state =~ /empty/i ) ) {
    if   ($opt_v) { print_verbose }
    else          { print "$printer_state\n\n"; }
    exit $ERRORS{'WARNING'};
}
else {
    if ( $printer_state =~ /error/i ) {
        if   ($opt_v) { print_verbose }
        else          { print "$printer_state\n\n"; }
        exit $ERRORS{'CRITICAL'};
    }
}
if ( !$opt_v ) { print "jobs=$jobs_scheduled\n"; }
exit $ERRORS{'OK'};
