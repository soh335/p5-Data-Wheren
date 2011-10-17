package Data::Wheren;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

our @ENC = qw(
00 01 02 03 10 11 12 13 20 21 22 23 30 31 32 33 40 41 42 43 50 51 52 53 60 61 62 63 70 71 72 73 80 81 82 83 90 91 92 93 b0 b1 b2 b3 c0 c1 c2 c3 d0 d1 d2 d3 e0 e1 e2 e3 f0 f1 f2 f3 g0 g1 g2 g3 h0 h1 h2 h3 j0 j1 j2 j3 k0 k1 k2 k3 m0 m1 m2 m3 n0 n1 n2 n3 p0 p1 p2 p3 q0 q1 q2 q3 r0 r1 r2 r3 s0 s1 s2 s3 t0 t1 t2 t3 u0 u1 u2 u3 v0 v1 v2 v3 w0 w1 w2 w3 x0 x1 x2 x3 y0 y1 y2 y3 z0 z1 z2 z3
);
our $ENC_WORD_LENGTH = 2;

our %DEC = map { $ENC[$_] => $_ } 0 .. $#ENC;

our $DATA = [
   [
      [0,8,64,72],
      [4,12,68,76],
      [32,40,96,104],
      [36,44,100,108],
   ],
   [
      [1,9,65,73],
      [5,13,69,77],
      [33,41,97,105],
      [37,45,101,109],
   ],
   [
      [2,10,66,74],
      [6,14,70,78],
      [34,42,98,106],
      [38,46,102,110],
   ],
   [
      [3,11,67,75],
      [7,15,71,79],
      [35,43,99,107],
      [39,47,103,111],
   ],
   [
      [16,24,80,88],
      [20,28,84,92],
      [48,56,112,120],
      [52,60,116,124],
   ],
   [
      [17,25,81,89],
      [21,29,85,93],
      [49,57,113,121],
      [53,61,117,125],
   ],
   [
      [18,26,82,90],
      [22,30,86,94],
      [50,58,114,122],
      [54,62,118,126],
   ],
   [
      [19,27,83,91],
      [23,31,87,95],
      [51,59,115,123],
      [55,63,119,127],
   ],
];

our $NEIGHBOR = _gen_neihbor();
our $BORDER = _gen_border();

sub new {
    my ($class, %args) = @_;

    $args{min_timestamp} ||= 0;
    $args{max_timestamp} ||= 2147451247; # 2038-01-19 03:14:7

    bless \%args, $class;
}

#my ($self, $lat, $lon, $timestamp, $level) = @_;
sub encode {
    my ($self, @pos) = @_;
    my $level = pop @pos;

    my $int = [ [ -90, 90 ], [ -180, 180 ], [ $self->{min_timestamp}, $self->{max_timestamp} ] ];
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
        push @enc, $ENC[$bits];
    }

    join "", @enc;
}

sub decode {
    my ($self, $str) = @_;

    my $int = $self->decode_to_interval($str);

    map { ( $_->[0] + $_->[1] ) / 2 } @$int;
}

sub decode_to_interval {
    my ($self, $str) = @_;

    my $int = [ [ -90, 90 ], [ -180, 180 ], [ $self->{min_timestamp}, $self->{max_timestamp} ] ];

    for my $ch ( $str =~ /.{$ENC_WORD_LENGTH}/g ) {
        if ( defined ( my $bits = $DEC{$ch} ) ) {
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

sub adjacent {
    my ($self, $str, $direction) = @_;

    $direction = lc $direction;
    my $base = substr($str, 0, -1);
    my $last_char = substr($str, -1, 1);

    my $index = $DEC{$last_char} or croak "";

    if ( defined $BORDER->{$direction}{$index} ) {
        $base = $self->adjacent($base, $direction);
    }

    $base . $ENC[$NEIGHBOR->{$direction}[$index]];
}

sub _search_data {
    my ($target, $func) = @_;

    my $floor_index = 0;
    for my $floor ( @$DATA ) {

        my $row_index = 0;
        for my $row ( @$floor ) {

            my $v_index = 0;
            for my $v ( @$row ) {
                if ( $v == $target ) {
                    return $func->($floor_index, $row_index, $v_index);
                }
                $v_index++;
            }
            $row_index++;
        }
        $floor_index++;
    }
    die "error in $target";
}

sub _gen_neihbor {

    my $neighbor = {};

    for my $i ( 0 .. 63 ) {

        #right
        my $right_list = $neighbor->{right} ||= [];
        push @$right_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $DATA->[$floor_index][$row_index][ ($v_index + 1) % 4];
            });

        # left 
        my $left_list = $neighbor->{left} ||= [];
        push @$left_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $v_index - 1;
                $n = 3 if $n < 0;
                return $DATA->[$floor_index][$row_index][ $n ];
            });

        #back
        my $back_list = $neighbor->{back} ||= [];
        push @$back_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $DATA->[$floor_index][ ($row_index + 1) % 4 ][$v_index];
            });

        #front
        my $front_list = $neighbor->{front} ||= [];
        push @$front_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $row_index - 1;
                $n = 3 if $n < 0;
                return $DATA->[$floor_index][$n][$v_index];
            });

        #top
        my $top_list = $neighbor->{top} ||= [];
        push @$top_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $DATA->[ ($floor_index + 1) % 4][$row_index][$v_index];
            });

        #bottom
        my $bottom_list = $neighbor->{bottom} ||= [];
        push @$bottom_list, _search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $floor_index - 1;
                $n = 3 if $n < 0;
                return $DATA->[$n][$row_index][$v_index];
            });
    }

    $neighbor;
}

sub _gen_border {
    my ($self) = @_;

    my $border = { right => {}, left => {}, top => {}, bottom => {}, back => {}, front => {} };

    for my $i ( 0 .. 3 ) {
        $border->{bottom}{$_} = 1 for @{$DATA->[0][$i]};
        $border->{top}{$_} = 1 for @{$DATA->[3][$i]};
    }

    for my $floor ( @$DATA ) {

        $border->{front}{$_} = 1 for @{$floor->[0]};
        $border->{back}{$_} = 1 for @{$floor->[3]};

        for my $row ( @$floor ) {
            $border->{left}{$row->[0]} = 1;
            $border->{right}{$row->[3]} = 1;
        }
    }

    $border;
}

1;
__END__

=head1 NAME

Data::Wheren - Perl extention to do something

=head1 VERSION

This document describes Data::Wheren version 0.01.

=head1 SYNOPSIS

    use Data::Wheren;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<YOUR NAME HERE>> E<lt><<YOUR EMAIL ADDRESS HERE>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, <<YOUR NAME HERE>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
