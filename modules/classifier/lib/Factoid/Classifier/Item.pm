package Factoid::Classifier::Item;

use strict;
use warnings;

use Params::Validate qw(:all);

use Factoid::Text::Ngrammer qw(get_ngrams ngram_to_str);
use Factoid::Classifier::BagOfWords;

sub new {
    my $class = shift;

    my $self = validate(@_, {
        text => { type => SCALAR }, 
        label => { type => SCALAR, regex => qr/^-?\d+$/, optional => 1 },
        type => { type => SCALAR, regex => qr/^(?:train|test)$/, optional => 1 },
    });
    
    return bless $self => $class;
}

sub text {
    my $self = shift;
    return $self->{text};
}

sub label {
    my $self = shift;
    return $self->{label};
}

sub predicted_label {
    my $self = shift;
    my ($value) = @_;
    if (defined($value)) {
        $self->{predicted_label} = $value;
    } else {
        return $self->{predicted_label};
    }
}

sub ngrams {
    my $self = shift;
    unless ($self->{ngrams}) {
        my %ngrams;
        my @ngrams_from_text = get_ngrams($self->text);
        for my $ngram (@ngrams_from_text) {
            my $ngram_str = ngram_to_str($ngram);
            unless ($ngrams{$ngram_str}->{ngram}) {
                $ngrams{$ngram_str}->{ngram} = $ngram;
            }
            $ngrams{$ngram_str}->{occurencies}++;
        }
        $self->{ngrams} = \%ngrams;
    }
    return $self->{ngrams};
}

sub ngrams_with_label {
    my $self = shift;
    my @ngrams_with_label;
    for my $ngram (values %{$self->ngrams}) {
        push @ngrams_with_label, [$ngram->{ngram}, $self->label];
    }
    return @ngrams_with_label;
}

1;
