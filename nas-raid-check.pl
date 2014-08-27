#!/usr/bin/perl
# Purpose: Check HAProxy BackEnd

#use strict;
use warnings;
my ($size, $logfile, $offsetfile, $crit, $warn, $pattern, $backend, $total, $brokenfile, $rebuildfile);
use Getopt::Std;
my %opts = ();
#$total = 0;
$state = 0;

use constant STATE_OK => 0;
use constant STATE_WARNING => 1;
use constant STATE_CRITICAL => 2;
use constant STATE_UNKNOWN => 3;

# process args and switches
getopts("f:o:c:w:p:b:r:", \%opts);

# try to detect plain logtail invocation without switches
if (!$opts{f} || !$opts{o} || !$opts{p} || !$opts{b} || !$opts{r}) {
   print STDERR "Missing Arguments.\n";
   exit STATE_UNKNOWN;
} else {
   ($logfile, $offsetfile, $crit, $warn, $pattern, $brokenfile, $rebuildfile) = ($opts{f}, $opts{o}, 
$opts{c}, $opts{w}, $opts{p}, $opts{b}, $opts{r});
}

if (! -f $logfile) {
    print STDERR "File $logfile cannot be read.\n";
    exit STATE_UNKNOWN;
}

unless (open(LOGFILE, $logfile)) {
    print STDERR "File $logfile cannot be read.\n";
    exit STATE_UNKNOWN;
}

my ($inode, $ino, $offset) = (0, 0, 0);

unless (not $offsetfile) {
    if (open(OFFSET, $offsetfile)) {
        $_ = <OFFSET>;
        unless (! defined $_) {
	    chomp $_;
	    $inode = $_;
	    $_ = <OFFSET>;
	    unless (! defined $_) {
	        chomp $_;
	        $offset = $_;
	    }
       }
    }

    unless ((undef,$ino,undef,undef,undef,undef,undef,$size) = stat 
$logfile) {
        print STDERR "Cannot get $logfile file size.\n", $logfile;
        exit STATE_UNKNOWN;
    }

    if ($inode == $ino) {
        if ($offset > $size) {
            $offset = 0;
        }
    }
    if ($inode != $ino || $offset > $size) {
        $offset = 0;
    }
    seek(LOGFILE, $offset, 0);
}


while (<LOGFILE>) {
    if (/\b$pattern\b/)  {
		$state = 2;
		unless (open (BROKEN, ">$brokenfile")) {
		die "Unable to open $brokenfile";
		}
	} elsif ($_ =~ /\bRebuild\b/) {
		$state = 1;
		system("rm $brokenfile");
        	unless (open (REBUILD, ">$rebuildfile")) {
        	die "Unable to open $rebuildfile";
		}	
	} else {
		if  ($_ =~ /\bOPTIMAL\b/) {
			$state = 0;
			system("rm $rebuildfile");
		}
	}	
}

$size = tell LOGFILE;
close LOGFILE;

unless (open(OFFSET, ">$offsetfile")) {
	print STDERR "File $offsetfile cannot be created. Check your 
permissions.\n";
        exit STATE_UNKNOWN;
}
print OFFSET "$ino\n$size\n";
close OFFSET;

if (-e $brokenfile) {
	print "RAID Device Degradated";
	close BROKEN;
	exit STATE_CRITICAL
}

if (-e $rebuildfile) {
        print "RAID Device rebuilding";
        close REBUILD;
        exit STATE_WARNING
}

if ($state == 2) {
	print "RAID Device Degradated";
	exit STATE_CRITICAL;
} elsif ($state == 1) {
	print "RAID Device is rebuilding";
	exit STATE_WARNING;
} else {
	print "RAID Device is OK";
	exit STATE_OK;
}

exit STATE_UNKNOWN;
