package Data::Wheren::6Bit;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Data::Wheren';
use Carp;

sub new {
    my ($class, %args) = @_;

    $args{enc} ||= [qw(
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ! -
        )];

    $args{data} ||= [
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

            if ( $bit ) {
                $int->[$flag][0] = $mid;
            }
            else {
                $int->[$flag][1] = $mid;
            }
            $bits = ( ( $bits << 1 ) | $bit );
        }
        push @enc, $self->{enc}[$bits];
    }

    join "", @enc;
}

sub decode_to_interval {
    my ($self, $str) = @_;

    my $int = $self->_gen_int;

    for my $ch ( split //, $str ) {
        if ( defined ( my $bits = $self->{dec}{$ch} ) ) {
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

1;
__END__

=head1 NAME

Data::Wheren::6Bit - Perl extention to do something

=head1 VERSION

This document describes Data::Wheren::6Bit version 0.01.

=head1 SYNOPSIS

    use Data::Wheren::6Bit;

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
