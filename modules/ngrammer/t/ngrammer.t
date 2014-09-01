#!/usr/bin/perl

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use lib qw(lib t/lib);

use Factoid::Text::Ngrammer qw(get_ngrams);

sub ngrams : Tests {
    my @ngrams = get_ngrams("Enjoyed my food. Cheesetots weren&#39;t bad :) :(", { verbose => 1 }); 

    cmp_deeply(\@ngrams, bag(
        ['enjoy'],
        ['enjoy', 'my'],
        ['enjoy', 'my', 'food'],
        ['were'],
        ['not_bad'],
        ['cheesetot', 'were'],
        ['were', 'not_bad'],
        ['cheesetot', 'were', 'not_bad'],
        [':)'],
        [':('],
    ), "Correct ngrams for sentences: Enjoyed my food. Cheesetots weren't bad :) :(") or diag explain \@ngrams;
}

__PACKAGE__->new->runtests;
