package Factoid::Text::Ngrammer;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(get_ngrams ngram_to_str);

use Params::Validate qw(:all);
use Factoid::Text::Tokenizer;

my $tokenizer = Factoid::Text::Tokenizer->new;

sub _is_word {
    my $word = shift;
    return ($word =~ m/^[A-Za-z0-9']+$/) ? 1 : undef;
}

sub _normalize_text {
    my $text = shift;

    my @sentences = @{$tokenizer->tokenize($text)};
    my @normalized_sentences;
    for my $sentence (@sentences) {
        my @words = grep { _is_word($_->{orig_word}) } @$sentence;
        my @smiles = grep { $tokenizer->is_smile($_->{orig_word}) } @$sentence; 

        #make correct normalized word
        for my $word (@words) {
            $word->{word} ||= $word->{lemma};
        }

        #merge not with next word if it is adjective or verb or adverb
        my $cur = 0;
        while ($cur < @words - 1) {
            if ($words[$cur]->{word} eq 'not' && ($words[$cur + 1]->{pos} eq 'JJ' || $words[$cur + 1]->{pos} eq 'VB' || $words[$cur + 1]->{pos} eq 'RB')) {
                $words[$cur] = $words[$cur + 1];
                splice @words, $cur + 1, 1;
                $words[$cur]->{word} = 'not_' . $words[$cur]->{word};
                $words[$cur]->{orig_word} = 'not+' . $words[$cur]->{orig_word};
            }
            ++$cur;
        }

        #add smiles
        for my $smile (@smiles) {
            push @words, { word => $smile->{orig_word} };
        }

        push @normalized_sentences, \@words;
    }
    return @normalized_sentences;
}

sub ngram_to_str {
    my ($ngram, $delimiter) = @_;
    $delimiter = ',' unless $delimiter;
    return join($delimiter, @$ngram);
}

sub _one_gram_filter {
    my ($ngram, $verbose, $debug_string) = @_;
    
    my %good_pos = (
        'JJ' => 1,
        'RB' => 1,
        'VB' => 1,
    );
    my $pos = $ngram->[0]->{pos};
    unless ($pos && $good_pos{$pos}) {
        warn "Not good pos $pos for ngram of length 1: $debug_string" if $verbose;
        return 0;
    }

    return 1
}

sub _n_gram_filter {
    my ($ngram, $verbose, $debug_string) = @_;

    my %good_pos = (
        'JJ' => 1,
        'RB' => 1,
        'VB' => 1,
    );
    my $has_good_pos = 0;
    for my $word (@$ngram) {
        $has_good_pos = 1 if $word->{pos} && $good_pos{$word->{pos}};
    }
    unless ($has_good_pos) {
        warn "No good pos for this ngram: $debug_string" if $verbose;
        return 0;
    }

    return 1;
}

sub _good_ngram {
    my ($ngram, $previous_word, $verbose) = @_;

    my $ngram_string = ngram_to_str([map { $_->{word} } @$ngram]);
    my $debug_string = $ngram_string;
    
    my $has_smiles = grep { $tokenizer->is_smile($_->{word}) } @$ngram; 
    if ($has_smiles) {
        if (@$ngram > 1) {
            warn "Has smiles and length > 1 so we don't add this ngram: $debug_string" if $verbose;
            return 0;
        } else {
            return 1;
        }
    }

    if ($previous_word && $previous_word->{word} =~ m{^not_}) {
        warn "Previous word is with 'NOT' so we don't add this ngram: $debug_string" if $verbose;
        return 0;
    }
    
    if (length($ngram_string) <= 3 + @$ngram - 1) { #there are @ngram - 1 spaces, we need at least 4 letters in the union of words
        warn "Ngram is too short: $debug_string" if $verbose;
        return 0;
    }
   
    if (@$ngram == 1) {
        return _one_gram_filter($ngram, $verbose, $debug_string);
    }

    if (@$ngram >= 2) {
        return _n_gram_filter($ngram, $verbose, $debug_string);
    }

    return 1; 
}

sub get_ngrams {
    my $text = shift;
    my $params = validate(@_, {
        sizes => { type => ARRAYREF, default => [1, 2, 3] },
        verbose => { type => BOOLEAN, default => 0, },
    });
    
    my @sentences = _normalize_text($text);
    my @ngrams;
    for my $sentence (@sentences) {
        my $string = join ' ', map { $_->{word} } @$sentence;
        warn "Normalized sentence: $string" if $params->{verbose};
        for my $size (@{$params->{sizes}}) {
            for my $start_idx (0 .. @$sentence - $size) {
                my @ngram = map { $sentence->[$_] } ($start_idx .. $start_idx + $size - 1);
                my $previous_word = ($start_idx > 0) ? $sentence->[$start_idx - 1] : undef;
                push @ngrams, [map { $_->{word} } @ngram] if _good_ngram(\@ngram, $previous_word, $params->{verbose});
            }
        }
    }
   
    return @ngrams;
}

1;
