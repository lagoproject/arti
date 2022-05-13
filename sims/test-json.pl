#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';
use LWP::Simple;
use JSON;

# read sitesLago.jsonld from LAGO DMP and obtain predefined site characteristics.
my $url="https://lagoproject.github.io/DMP/defs/sitesLago.jsonld";
my $jsonld;
die "could not get $url\n" unless (defined($jsonld = get $url));
my $decoded = decode_json($jsonld);
my @sites_json = @{ $decoded->{'@graph'} };
my %sites = ();
my $n = 0;
foreach my $s ( @sites_json ) {
    $sites { $s->{'@id'} } = [
        $s->{'lago:atmcrd'}{'lago:modatm'}{'@default'},
        $s->{'lago:obsLev'}{'@default'},
        $s->{'lago:magnet'}{'@default'}{'lago:bx'},
        $s->{'lago:magnet'}{'@default'}{'lago:bz'}
    ];
    $n++;
}
print("$n\n");
foreach my $s ( keys %sites ) {
    print "$s: @{ $sites{$s} }\n";
}
my $tst = "and";
if (defined $sites{"$tst"}) {
    print "$tst: @{ $sites{$tst} }\n";
} else {
    print "$tst not found\n";
}