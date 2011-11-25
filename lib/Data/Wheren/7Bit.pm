package Data::Wheren::7Bit;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Data::Wheren::Base';
use Carp;

sub new {
    my ($class, %args) = @_;

    $args{enc} ||= [ qw(
        00 01 02 03 10 11 12 13 20 21 22 23 30 31 32 33 40 41 42 43 50 51 52 53 60 61 62 63 70 71 72 73 80 81 82 83 90 91 92 93 b0 b1 b2 b3 c0 c1 c2 c3 d0 d1 d2 d3 e0 e1 e2 e3 f0 f1 f2 f3 g0 g1 g2 g3 h0 h1 h2 h3 j0 j1 j2 j3 k0 k1 k2 k3 m0 m1 m2 m3 n0 n1 n2 n3 p0 p1 p2 p3 q0 q1 q2 q3 r0 r1 r2 r3 s0 s1 s2 s3 t0 t1 t2 t3 u0 u1 u2 u3 v0 v1 v2 v3 w0 w1 w2 w3 x0 x1 x2 x3 y0 y1 y2 y3 z0 z1 z2 z3
        )];
    $args{enc_world_length} ||= 2;

    $args{data} ||= [
        [
            [0,4,32,36],
            [8,12,40,44],
            [64,68,96,100],
            [72,76,104,108],
        ],
        [
            [1,5,33,37],
            [9,13,41,45],
            [65,69,97,101],
            [73,77,105,109],
        ],
        [
            [2,6,34,38],
            [10,14,42,46],
            [66,70,98,102],
            [74,78,106,110],
        ],
        [
            [3,7,35,39],
            [11,15,43,47],
            [67,71,99,103],
            [75,79,107,111],
        ],
        [
            [16,20,48,52],
            [24,28,56,60],
            [80,84,112,116],
            [88,92,120,124],
        ],
        [
            [17,21,49,53],
            [25,29,57,61],
            [81,85,113,117],
            [89,93,121,125],
        ],
        [
            [18,22,50,54],
            [26,30,58,62],
            [82,86,114,118],
            [90,94,122,126],
        ],
        [
            [19,23,51,55],
            [27,31,59,63],
            [83,87,115,119],
            [91,95,123,127],
        ],
    ];

    $class->SUPER::new(%args);
}

#my ($self, $lat, $lon, $timestamp, $level) = @_;
sub encode {
    my ($self, @pos) = @_;
    my $level = pop @pos;

    my $int = $self->_gen_int;
    my @enc = ();

    for my $i ( 1 .. $level ) {
        my $bits = 0;
        for my $j ( 0 .. 5 ) {
            my $flag = $j % 3;

            my $mid = ($int->[$flag][0] + $int->[$flag][1]) / 2;
            my $bit = $pos[$flag] >= $mid ? 1 : 0;

            $int->[$flag][$bit ? 0 : 1] = $mid;
            $bits = ( ( $bits << 1 ) | $bit );
        }
        my $mid = ($int->[2][0] + $int->[2][1])/2;
        my $bit = $pos[2] >= $mid ? 1 : 0;

        $int->[2][$bit ? 0 : 1] = $mid;
        $bits = ( ( $bits << 1 ) | $bit );
        push @enc, $self->{enc}[$bits];
    }

    join "", @enc;
}

sub decode_to_interval {
    my ($self, $str) = @_;

    my $int = $self->_gen_int;

    for my $ch ( $str =~ /.{$self->{enc_world_length}}/g ) {
        if ( defined ( my $bits = $self->{dec}{$ch} ) ) {
            for my $j ( 0 .. 5 ) {
                my $flag = $j % 3;
                $int->[$flag][ ( $bits & 64 ) >> 6 == 0 ? 1 : 0 ] = ( $int->[$flag][0] + $int->[$flag][1] ) / 2;
                $bits <<= 1;
            }
            $int->[2][ ( $bits & 64 ) >> 6 == 0 ? 1 : 0 ] = ( $int->[2][0] + $int->[2][1] ) / 2;
        }
        else {
            croak "Bad character '$ch' in hash '$str'";
        }
    }

    $int;
}

1;
__END__

=head1 NAME

Data::Wheren::7Bit - Perl extention to do something

=head1 VERSION

This document describes Data::Wheren::7Bit version 0.01.

=head1 SYNOPSIS

    use Data::Wheren::7Bit;

    my $wheren = Data::Wheren::7Bit->new;
    my $hash = $wheren->encode( $lat, $lon, $epoch_time, $level );
    my ($lat, $lon, $epoch_time) = $wheren->decode( $hash );

=head1 DESCRIPTION

Data::Wheren::7Bit encodes and decodes wheren strings as 7Bit mode.

=head1 METHODS

=head2 $wheren = Data::Wheren::7Bit->new(%args);

Arguments can be:

=over

=item * C<enc>

=item * C<enc_world_length>

=item * C<data>

=item * C<min>

=item * C<max>

=back

=head2 $hash = $wheren->encode($lat, $lon, $epoch_time, $level)

Encodes the given $lat, $lon and $epoch_time to a wheren. 

=head2 ($lat, $lon, $epoch_time) = $wheren->decode( $hash )

Decodes $hash to $lat, $lon and $epoch_time

=head2 [$lat_range, $lon_range, $epoch_time_range] = $wheren->decode_to_interval( $hash )

Like C<deocde()> but C<decode_to_interval()> decodes $hash to $lat_range, $lon_range and $epoch_time_range. Each range is a reference to two elements arrays which contains the upper and lower bounds.

=head2 $hash = $wheren->adjacent($hash, $direction)

Returns the adjacent wheren. C<$direction> should be C<right>, C<left>, C<front>, C<back>, C<bottom>, C<top>.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Data::Wheren::Base>
L<Data::Wheren::6Bit>

=head1 AUTHOR

<<Soh Kitahara>> E<lt><<sugarbabe335+perl@gmail.com>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, <<Soh Kitahara>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
