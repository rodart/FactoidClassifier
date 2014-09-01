#!/usr/bin/perl
# vim: ft=perl

use Moose;

use Factoid::Classifier::BagOfWords;

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    traits => ['Getopt'],
);

sub main {
    my $self = shift;
    my $bow = Factoid::Classifier::BagOfWords->new({ name => $self->name });
    print $bow->pretty_dump;
}

__PACKAGE__->run_script;
