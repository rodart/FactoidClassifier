package Factoid::Text::Tokenizer;

use strict;
use warnings;

=head1 NAME

Factoid::Text::Tokenizer - tokenize input text on separate sentences and than each sentence tokineze on separate tokens. Token - word or smile.
Before tokenization it also remove html tags.

=cut

use HTML::Strip;
use Lingua::Sentence;
use Text::StemTagPOS;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub get_tokens {
    my $sentence = shift;

    my @smiles = get_smiles($sentence);
    my $smile = get_smile_template();
    $sentence =~ s/$smile//g;

    my @words = get_tagged_words($sentence);
    my @tokens = (@words, @smiles);
    return \@tokens;
}

sub get_tagged_words {
    my $sentence = shift;

    my @words;
    my $stemTagger = Text::StemTagPOS->new();
    my $tagged_sentence = $stemTagger->getStemmedAndTaggedText($sentence);
    for my $lemma (@{ $tagged_sentence->[0] }) {
        my $pos = substr($lemma->[2], 1, 2);
        if ($pos ne 'PG' and $pos ne 'PP' and $pos ne 'LR' and $pos ne 'RR') {
            my $word->{lemma} = $lemma->[0];
            $word->{lemma} = 'not' if $word->{lemma} eq "n't";
            $word->{orig_word} = $lemma->[1];
            $word->{pos} = $pos;
            push @words, $word;
        }
    }

    return @words;
}

sub get_sentences {
    my $text = shift;

    my $splitter = Lingua::Sentence->new("en");
    my @sentences = $splitter->split_array($text);
    
    return \@sentences;
}

sub get_text_without_html {
    my $raw_text = shift;

    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse( $raw_text );
    
    return $clean_text;
}

sub get_smiles {
    my $sentence = shift;

    my $smile = get_smile_template();
    my (@smiles) = $sentence =~ m/$smile/g;
    
    my @transformed_smiles;
    for my $smile (@smiles) {
        push @transformed_smiles, { orig_word => $smile };
    }
    return @transformed_smiles;
}

sub get_smile_template {
    my $eyes = '[:;=8]';
    my $nose = '[\-o\*\']?';
    my $mouth = '[\)\]\(\[dDpP\/:\}\{@\|]';
    my $repeating_mouth = '[\)\(]{2,}';
    my $smile = $eyes . $nose . $mouth . "|" . $mouth . $nose . $eyes . "|" . $repeating_mouth;
    
    return $smile;
}

=item B<is_smile>($token)

Check if token is smile

=cut

sub is_smile {
    my ($self, $token) = @_;
   
    my $smile = get_smile_template();
    
    return $token =~ m/$smile/;
}


=item B<tokenize>($text)

Returs arrayref of arrayrefs, each arrayref is one tokenized sentence.

=cut

sub tokenize {
    my ($self, $text) = @_;
    my $clean_text = get_text_without_html($text); 
    my $sentences = get_sentences($clean_text);

    my @tokenized_sentences;
    for my $sentence (@$sentences) {
        push @tokenized_sentences, get_tokens($sentence); 
    }

    return \@tokenized_sentences;
}

1;
