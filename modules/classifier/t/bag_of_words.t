#!/usr/bin/perl

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;

use lib qw(lib);

use Factoid::Classifier::BagOfWords;

sub test : Tests {
    
    my $bow = Factoid::Classifier::BagOfWords->new({ name => "test" });
    $bow->build([
        [['very', 'cool'], 1],
        [['vere', 'cool'], 1],
        [['not_very', 'cool'], -1],
        [['not_very', 'cool'], -1],
        [['good'], 1],
        [['cool'], 1],
        [['cool'], 1],
    ]);
    note explain $bow;
    $bow->save;
    
    my $bow2 = Factoid::Classifier::BagOfWords->new({ name => "test" });
    cmp_deeply($bow->{ngrams}, $bow2->{ngrams}, 'Same ngrams from initial and loaded model');

    cmp_ok($bow->{ngrams}->{'cool'}->{didf}, '>', '0', '"Cool" is a sentiment positive ngram');
    cmp_ok($bow->{ngrams}->{'not_very,cool'}->{didf}, '<', '0', '"not_very cool" is a sentiment negative ngram');
    print $bow->pretty_dump;
}

__PACKAGE__->new->runtests;
