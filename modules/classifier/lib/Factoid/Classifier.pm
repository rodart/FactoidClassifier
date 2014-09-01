package Factoid::Classifier;

use strict;
use warnings;

use Params::Validate qw(:all);

use Factoid::Text::Ngrammer qw(ngram_to_str);

sub new {
    my $class = shift;
    my $self = validate(@_, {
        name => { type => SCALAR },
        bow_name => { type => SCALAR, optional => 1 },
        bow_models_dir => { type => SCALAR, optional => 1 },
        bow => { optional => 1 },
    });
    $self->{bow_name} ||= $self->{name};
    bless $self => $class;
    return $self;
}

sub bow_model {
    my $self = shift;
    unless ($self->{bow}) {
        my $params = {
            name => $self->{bow_name}
        };
        $params->{models_dir} = $self->{bow_models_dir} if $self->{bow_models_dir};
        $self->{bow} = Factoid::Classifier::BagOfWords->new($params);
    }
    return $self->{bow};
}

sub _get_weights {
    my $self = shift;
    my $item = shift;
    my ($verbose) = @_;
    my $bow = $self->bow_model;
    my @ngrams = grep { defined($bow->id($_)) } map { $_->{ngram} } values %{$item->ngrams};
    unless (@ngrams) {
        print "No ngrams for text " . $item->text . "\n" if $verbose;
        return;
    }
    my @weights;
    for my $ngram (@ngrams) {
        print "Ngram " . ngram_to_str($ngram) . ": " . $bow->dtfidf($ngram, $item->ngrams->{ngram_to_str($ngram)}->{occurencies}) / $bow->max_didf . '\n' if $verbose;
        push @weights, $bow->dtfidf($ngram, $item->ngrams->{ngram_to_str($ngram)}->{occurencies}) / $bow->max_didf;
    }
    return @weights;
}

sub predict {
    my $self = shift;
    my $item = shift;
    my $params = validate(@_, {
        verbose => { type => BOOLEAN, default => 0 },
    });
    
    my @weights = $self->_get_weights($item, $params->{verbose});
    if (@weights) {
        my $sum = 0;
        for my $weight (@weights) {
            $sum += $weight;
        }
        $item->predicted_label(($sum >= 0) ? 1 : -1 );
    } else {
        $item->predicted_label(0);
    }
    
    return $item->predicted_label;
}

1;
