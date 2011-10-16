package Data::SpatioTemporalHash;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

our @ENC = qw(
  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ! -
  );
our $ENC_WORD_LENGTH = 1;

our %DEC = map { $ENC[$_] => $_ } 0 .. $#ENC;

our $DATA = [
    [
        [0, 4, 32, 36],
        [2, 6, 34, 38],
        [16, 20, 48, 52],
        [18, 22, 50, 54]
    ],
    [
        [1, 5, 33, 37],
        [3, 7, 35, 39],
        [17, 21, 49, 53],
        [19, 23, 51, 55]
    ],
    [
        [8, 12, 40, 44],
        [10, 14, 42, 46],
        [24, 28, 56, 60],
        [26, 30, 58, 62]
    ],
    [
        [9, 13, 41, 45],
        [11, 15, 43, 47],
        [25, 29, 57, 61],
        [27, 31, 59, 63]
    ]
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

            if ( $bit ) {
                $int->[$flag][0] = $mid;
            }
            else {
                $int->[$flag][1] = $mid;
            }
            $bits = ( ( $bits << 1 ) | $bit );
        }
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
                $int->[$flag][ ( $bits & 32 ) >> 5 == 0 ? 1 : 0 ] = ( $int->[$flag][0] + $int->[$flag][1] ) / 2;
                $bits <<= 1;
            }
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

    #warn $NEIGHBOR->{$direction}->[$index];
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

Data::SpatioTemporalHash - Perl extention to do something

=head1 VERSION

This document describes Data::SpatioTemporalHash version 0.01.

=head1 SYNOPSIS

    use Data::SpatioTemporalHash;

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
