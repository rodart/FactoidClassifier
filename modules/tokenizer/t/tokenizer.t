#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib qw(lib t/lib);

use Factoid::Text::Tokenizer;

my $tokenizer = Factoid::Text::Tokenizer->new;

{
    my $str = 'The only burger I wouldn&#39;t recommend is the avocado-ranch - but that&#39;s because I felt like it didn&#39;t come with as much avocado as it should. Might be the 20-30 Cali-avocados snob in me =).<br><br>Large restaurant, lots of tv&#39;s - good place to bring a large 4 group!';
    my $sentences = $tokenizer->tokenize($str);

    my @orig_forms;
    for my $sentence (@$sentences) {
        my @orig_form = map { $_->{orig_word} } @$sentence;
        push @orig_forms, \@orig_form;
    }

    is_deeply(\@orig_forms, 
        [ 
            ['The','only','burger','I',"would", "n't",'recommend','is','the','avocado','ranch','but',"that", "'s",'because','I','felt','like','it',"did", "n't",'come','with','as','much','avocado','as','it','should'], 
            ['Might','be','the','20', '30','Cali','avocados','snob','in','me','=)'],
            ['Large','restaurant','lots','of',"tv", "'s",'good','place','to','bring','a','large','4','group'],
        ], 'Correct sentence tokenization');

    is($tokenizer->is_smile('=)'), 1, 'Correct smile =)');
    is($tokenizer->is_smile('):'), 1, 'Correct smile ):');
    is($tokenizer->is_smile('=*D'), 1, 'Correct smile =*D');
    is($tokenizer->is_smile('((('), 1, 'Correct smile (((');
}


done_testing();
