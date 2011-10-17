#!perl -w
use strict;
use Test::More;

use Data::Wheren;
use Time::Piece;

# test Data::Wheren here
my $sth = Data::Wheren->new;
my $timestamp = Time::Piece->strptime("2010-01-01 00:00:00", "%Y-%m-%d %T")->epoch;
my $str = $sth->encode(35.8, 134.3, $timestamp, 9);
warn "";
warn "timestamp: $timestamp";
warn "encode: $str";

my ($lat, $lon, $time) = $sth->decode($str);
warn "lat: $lat, lon: $lon, time: $time";

warn "---bottom---";

$str = $sth->adjacent($str, "bottom");
warn $str;
($lat, $lon, $time) = $sth->decode($str);
warn "lat: $lat, lon: $lon, time: $time";

done_testing;
