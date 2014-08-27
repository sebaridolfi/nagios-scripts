#!/usr/bin/perl
# Purpose: Check HAProxy BackEnd

my ($logfile, $pattern, $backend);
use Getopt::Std;
my %opts = ();
my %backends_status = ();
my %backends_up = ();
my $state = 0;

use constant STATE_OK => 0;
use constant STATE_WARNING => 1;
use constant STATE_CRITICAL => 2;
use constant STATE_UNKNOWN => 3;

# process args and switches
getopts("f:o:c:w:p:d:", \%opts);

# try to detect plain logtail invocation without switches
if (!$opts{f} || !$opts{p}) {
   print STDERR "Missing Arguments.\n";
   exit STATE_UNKNOWN;
} else {
   ($logfile, $pattern) = ($opts{f}, $opts{p});
}

if (! -f $logfile) {
    print STDERR "File $logfile cannot be read.\n";
    exit STATE_UNKNOWN;
}

unless (open(LOGFILE, $logfile)) {
    print STDERR "File $logfile cannot be read.\n";
    exit STATE_UNKNOWN;
}

while (<LOGFILE>) {
    	if (/\b$pattern\b/)  {
		my $string = $_;
                my @values = split(" ",$string);
                foreach my $val (@values) {
                        if ($val =~ /b_/) {
				$backends_status{$val} = 'DOWN';
			}	

		}
	}
	if (/\bUP\b/) {
                my $string2 = $_;
                my @values2 = split(" ",$string2);
                foreach my $val2 (@values2) {
                        if ($val2 =~ /b_/) {
                                @val3 = split("/",$val2);
				undef $_;
				for (keys %backends_status) {
					if (@val3[0] eq $_) {
						$backends_status{$_} = 'UP';
					}
				}
			}
		}
	}
		
}

for (keys %backends_status) {
	if ($backends_status{$_} eq 'DOWN') {
		@backends_down = (@backends_down, "$_ ");
		$state = 2;
	} 
}
	

if ($state == 2) {
	print "@backends_down\DOWN";
	exit STATE_CRITICAL;
}

if ($state == 0) {
	print "All Backends OK\n";
	exit STATE_OK;
}

print "UNKNOWN";
exit STATE_UNKNOWN;
