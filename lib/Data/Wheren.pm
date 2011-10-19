package Data::Wheren;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

sub new {
    my ($class, %args) = @_;

    croak "should override" if $class eq "Data::Wheren";

    $args{min} ||= 0;
    $args{max} ||= 2147451247; # 2038-01-19 03:14:7
    $args{dec} = +{ map { $args{enc}->[$_] => $_ } 0 .. scalar @{$args{enc}} - 1};

    my $self = bless \%args, $class;

    $self->{neighbor} = $self->_gen_neihbor();
    $self->{border} = $self->_gen_border();

    $self;
}

sub _gen_int {
    my $self = shift;
    [ [ -90, 90 ], [ -180, 180 ], [ $self->{min}, $self->{max} ] ];
}

#my ($self, $lat, $lon, $timestamp, $level) = @_;
sub encode {
    croak "should be override encode method";
}

sub decode {
    my ($self, $str) = @_;

    my $int = $self->decode_to_interval($str);

    map { ( $_->[0] + $_->[1] ) / 2 } @$int;
}

sub decode_to_interval {
    croak "should be override decode_to_interval method";
}

sub adjacent {
    my ($self, $str, $direction) = @_;

    $direction = lc $direction;
    my $base = substr($str, 0, -1);
    my $last_char = substr($str, -1, 1);

    my $index = $self->{dec}->{$last_char} or croak "";

    if ( defined $self->{border}->{$direction}{$index} ) {
        $base = $self->adjacent($base, $direction);
    }

    $base . $self->{enc}->[$self->{neighbor}->{$direction}[$index]];
}

sub _search_data {
    my ($self, $target, $func) = @_;

    my $floor_index = 0;
    for my $floor ( @{$self->{data}} ) {

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
    my ($self) = @_;

    my $neighbor = {};

    for my $i ( 0 .. 63 ) {

        #right
        my $right_list = $neighbor->{right} ||= [];
        push @$right_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $self->{data}->[$floor_index][$row_index][ ($v_index + 1) % 4];
            });

        # left 
        my $left_list = $neighbor->{left} ||= [];
        push @$left_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $v_index - 1;
                $n = 3 if $n < 0;
                return $self->{data}->[$floor_index][$row_index][ $n ];
            });

        #back
        my $back_list = $neighbor->{back} ||= [];
        push @$back_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $self->{data}->[$floor_index][ ($row_index + 1) % 4 ][$v_index];
            });

        #front
        my $front_list = $neighbor->{front} ||= [];
        push @$front_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $row_index - 1;
                $n = 3 if $n < 0;
                return $self->{data}->[$floor_index][$n][$v_index];
            });

        #top
        my $top_list = $neighbor->{top} ||= [];
        push @$top_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                return $self->{data}->[ ($floor_index + 1) % 4][$row_index][$v_index];
            });

        #bottom
        my $bottom_list = $neighbor->{bottom} ||= [];
        push @$bottom_list, $self->_search_data($i, sub {
                my ($floor_index, $row_index, $v_index) = @_;
                my $n = $floor_index - 1;
                $n = 3 if $n < 0;
                return $self->{data}->[$n][$row_index][$v_index];
            });
    }

    $neighbor;
}

sub _gen_border {
    my ($self) = @_;

    my $border = { right => {}, left => {}, top => {}, bottom => {}, back => {}, front => {} };

    for my $i ( 0 .. 3 ) {
        $border->{bottom}{$_} = 1 for @{$self->{data}->[0][$i]};
        $border->{top}{$_} = 1 for @{$self->{data}->[3][$i]};
    }

    for my $floor ( @{$self->{data}} ) {

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
