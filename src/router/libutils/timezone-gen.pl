#!/usr/bin/perl

use strict;
use Getopt::Long;

my $base   = "/usr/share/zoneinfo";
my $output = "timezones.inc";
my $debug;
my $help;

my %zones        = ();
my %name_to_file = ();

my $res = GetOptions(
    "base=s" => \$base,
    "debug+" => \$debug,
    "help"   => \$help,
    "output" => \$output
);
if ( !$res || $help ) {
    print "$0 [--base=/usr/share/zoneinfo] [--output=timezones.inc] [--debug] [--help]\n";
    exit;
}

my @dirs = ($base);

while (@dirs) {
    my $dir = shift @dirs;
    # SKIP ROOT LINKS
    # next if ( -l "$file" );

    opendir( my $top, $dir );
    while ( my $file = readdir($top) ) {
        next if ( $file eq "." || $file eq ".." || $file eq "Etc" );
	# START FILTERS
	next if ( $file eq "CET" );
	next if ( $file eq "CST6CDT" );
	# next if ( $file eq "Cuba" );   # Asia/Havana
	next if ( $file eq "EST" );
	next if ( $file eq "EST5EDT" );
	next if ( $file eq "EET" );
	next if ( $file eq "Egypt" );
	next if ( $file eq "EET" );
	next if ( $file eq "Eire" );
	next if ( $file eq "Factory" );
	next if ( $file eq "GB" );       # Europe/London
	next if ( $file eq "GB-Eire" );
	next if ( $file eq "GMT" );
	next if ( $file eq "GMT0" );
	next if ( $file eq "GMT-0" );
	next if ( $file eq "GMT+0" );
	# next if ( $file eq "Greenwich" );
	next if ( $file eq "HST" );
	next if ( $file eq "Hongkong" );
	next if ( $file eq "Iceland" );  # Grinvich
	# next if ( $file eq "Iran" );     # Asia/Tehran
	next if ( $file eq "Israel" );   # Asia/Tel Aviv
	# next if ( $file eq "Jamaica" );
	next if ( $file eq "Japan" );    # Asia/Tokyo
	next if ( $file eq "Kwajalein" );
	next if ( $file eq "Libya" );
	next if ( $file eq "localtime" );
	next if ( $file eq "MET" );
	next if ( $file eq "MST" );
	next if ( $file eq "MST7MDT" );
	next if ( $file eq "MST8MDT" );
	next if ( $file eq "Navajo" );
	next if ( $file eq "NZ" );
	next if ( $file eq "NZ-CHAT" );
	next if ( $file eq "Pacific-New" );
	next if ( $file eq "Poland" );
	next if ( $file eq "Portugal" );
	next if ( $file eq "posix" );
	next if ( $file eq "posixrules" );
	next if ( $file eq "PRC" );      # Asia/Shanghai
	next if ( $file eq "PST8PDT" );
	next if ( $file eq "right" );
	next if ( $file eq "ROC" );
	next if ( $file eq "ROK" );
	# next if ( $file eq "Singapore" );
	next if ( $file eq "SystemV" );
	next if ( $file eq "Turkey" );
	next if ( $file eq "UCT" );
	next if ( $file eq "Universal" );
	next if ( $file eq "UTC" );
	next if ( $file eq "W-SU" );
	next if ( $file eq "WET" );
	next if ( $file eq "Zulu" );
	# END FILTERS

        if ( -f "$dir/$file" ) {
            $debug && print "Found $dir/$file\n";
	    # if ( -l "$dir/$file" ) {
		# $debug && print "Skip symlink $dir/$file\n";
                # next;
            # }
            my $name = "$dir/$file";
            $name =~ s|^${base}/||o;

            $name_to_file{$name} = "$dir/$file";
        }
        elsif ( -d "$dir/$file" ) {
            $debug && print "Found subdir $dir/$file\n";
            push( @dirs, "$dir/$file" );
        }
    }
    closedir($top);
}

foreach my $name ( sort( keys(%name_to_file) ) ) {
    my $file = $name_to_file{$name};
    $debug && print "Processing $file...\n";

    open( my $in, "<$file" );
    my $data = join( "", <$in> );
    close($in);

    my @strings = $data =~ (m/[ -~]{4,}/g);
    if ( shift(@strings) !~ /^TZif/o ) {
        $debug && print "Skipped $file\n";
        next;
    }

    $zones{$name} = pop(@strings);
}

open( my $out, ">$output" );
print $out "TIMEZONE_TO_TZSTRING allTimezones[] = {\n";

my $lastprefix = "";
foreach my $zone ( sort( keys(%zones) ) ) {
    my $str = $zones{$zone};
    next if ( !$str );
    # Empty lines
    # my $newprefix = $zone;
    # $newprefix =~ s|/.*||go;
    # if ( $newprefix ne $lastprefix && $lastprefix ne "" ) {
    #    print $out "\n";
    # }
    # $lastprefix = $newprefix;

    # Remove underscopes from zones names
    $zone =~ tr|_| |;
    # Fancy zones names separators /->
    # $zone =~ tr|/|\||;

    print $out "\t{\"$zone\", \"$str\"}\n\t,\n";
}
print $out "\t" x 1, "{NULL, NULL}\n";
print $out "};\n";
close($out);
