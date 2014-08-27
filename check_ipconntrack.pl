#!/usr/bin/perl
# Date: 19.08.2014
# Purpose: Check IP Contrack Values
my ($critical, $warning);
use Getopt::Std;
use File::Basename;

use constant STATE_OK => 0;
use constant STATE_WARNING => 1;
use constant STATE_CRITICAL => 2;
use constant STATE_UNKNOWN => 3;

# process args and switches
getopts("c:w:", \%opts);

# try to detect plain logtail invocation without switches
if (!$opts{c} || !$opts{w}) {
   print STDERR "Missing Arguments.\n";
   exit STATE_UNKNOWN;
} else {
   ($c, $w) = ($opts{c}, $opts{w});
}

open COUNT, "</proc/sys/net/ipv4/netfilter/ip_conntrack_count";
open MAX, "</proc/sys/net/ipv4/netfilter/ip_conntrack_max";
$ipcontrack_count = <COUNT>;
$ipcontrack_max = <MAX>;

$ipcontrack_usage = (($ipcontrack_count * 100 ) / $ipcontrack_max);
$ipcontrack_free = 100 - $ipcontrack_usage;

if ($ipcontrack_free <= $critical) {
	print "IP Contrack Usage Critical $ipcontrack_count/$ipcontrack_max Used: $ipcontrack_usage%\n";
	exit STATE_CRITICAL;
} elsif (($ipcontrack_free > $crtical) && ($ipcontrack_free <= $warning)) {
	print "IP Contrack Usage Warning $ipcontrack_count/$ipcontrack_max Used: $ipcontrack_usage%\n";
	exit STATE_WARNING;
} elsif ($ipcontrack_free > $warning) { 
	print "IP Contrack Usage OK\n";
	exit STATE_OK;
}
print  basename(__FILE__), " Unkwnon, check script\n";
exit STATE_UNKNOWN;
