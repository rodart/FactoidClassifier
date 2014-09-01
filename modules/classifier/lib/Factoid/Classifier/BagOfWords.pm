package Factoid::Classifier::BagOfWords;

use strict;
use warnings;

use Params::Validate qw(:all);
use Storable qw(store retrieve);

use Factoid::Text::Ngrammer qw(ngram_to_str);

my $MODELS_DIR = '/var/spool/libfactoid-classifier-perl/bag_of_words_models';                                                                                                                           
my $EPS = 0.5;
my $MIN_OCCURENCIES_OF_NGRAM = 2;
my $POS_LABEL = 1;
my $NEG_LABEL = -1;

sub new {
    my $class = shift;
    my $self = validate(@_, {
        name => { type => SCALAR },
        models_dir => { type => SCALAR, default => $ENV{BOW_MODELS_DIR} || $MODELS_DIR },
    });
    bless $self => $class;
    
    $self->load if _exists($self->{models_dir}, $self->{name});
    
    return $self;
}

sub _exists {
    my ($dir, $name) = @_;
    return -e "$dir/$name.bow";
}

sub load {
    my $self = shift;
    unless (_exists($self->{models_dir}, $self->{name})) {
        die "Model $self->{name} not found!";
    }
    $self->{ngrams} = retrieve "$self->{models_dir}/$self->{name}.bow";
}

sub save {
    my $self = shift;
    store $self->{ngrams}, "$self->{models_dir}/$self->{name}.bow";
}


sub _filter_ngrams {
    my $self = shift;
    for my $ngram_str (keys %{$self->{ngrams}}) {
        my $good = 1;
        unless ($self->{ngrams}->{$ngram_str}->{num_pos} + $self->{ngrams}->{$ngram_str}->{num_neg} >= $MIN_OCCURENCIES_OF_NGRAM) {
            $good = 0;
        }
        delete $self->{ngrams}->{$ngram_str} unless $good;
    }
}

sub build {
    my $self = shift;
    my $ngrams = shift;
    unless (ref $ngrams eq 'ARRAY') {
        die "Arrayref with ngrams required!";
    }
    $self->{ngrams} = {};
    $self->{max_didf} = 0;
    my $num_positive = 0;
    my $num_negative = 0;
    for my $ngram_and_label (@$ngrams) {
        my ($ngram, $label) = @$ngram_and_label;
        my $ngram_str = ngram_to_str($ngram);
        unless ($self->{ngrams}->{ngram_to_str($ngram)}) {
            $self->{ngrams}->{$ngram_str}->{ngram} = $ngram;
            $self->{ngrams}->{$ngram_str}->{num_pos} = 0;
            $self->{ngrams}->{$ngram_str}->{num_neg} = 0;
        }
        if ($label == $POS_LABEL) {
            $self->{ngrams}->{$ngram_str}->{num_pos}++;
            ++$num_positive;
        }
        if ($label == $NEG_LABEL) {
            $self->{ngrams}->{$ngram_str}->{num_neg}++;
            ++$num_negative;
        }
    }

    $self->_filter_ngrams;

    my $id = 0;
    for my $ngram_str (keys %{$self->{ngrams}}) {
        $self->{ngrams}->{$ngram_str}->{id} = $id++;
        $self->{ngrams}->{$ngram_str}->{didf} = log((($self->{ngrams}->{$ngram_str}->{num_pos} + $EPS) * $num_negative) /
            (($self->{ngrams}->{$ngram_str}->{num_neg} + $EPS) * $num_positive));
    }
}

sub didf {
    my $self = shift;
    my $ngram = shift;
    if ($self->{ngrams}->{ngram_to_str($ngram)}) {
        return $self->{ngrams}->{ngram_to_str($ngram)}->{didf};
    }
    else {
        return undef;
    }
}

sub max_didf {
    my $self = shift;
    unless ($self->{max_didf}) {
        $self->{max_didf} = 0;
        for my $ngram_str (keys %{$self->{ngrams}}) {
            my $ngram = $self->{ngrams}->{$ngram_str};
            unless (defined $ngram->{didf}) {
                die "No didf for $ngram_str!";
            }
            if (abs($ngram->{didf}) >= $self->{max_didf}) {
                $self->{max_didf} = abs($ngram->{didf});
            }
        }
    }
    return $self->{max_didf};
}

sub dtfidf {
    my $self = shift;
    my ($ngram, $occurencies) = @_;
    if ($self->{ngrams}->{ngram_to_str($ngram)}) {
        return $occurencies * $self->didf($ngram);
    }
    else {
        return undef;
    }
}

sub id {
    my $self = shift;
    my $ngram = shift;
    if ($self->{ngrams}->{ngram_to_str($ngram)}) {
        return $self->{ngrams}->{ngram_to_str($ngram)}->{id};
    }
    else {
        return undef;
    }
}

sub pretty_dump {
    my $self = shift;
    my $result = '';
    for my $ngram_str (keys %{$self->{ngrams}}) {
        my $ngram = $self->{ngrams}->{$ngram_str};
        $result .= join("\t", $ngram_str, $ngram->{id}, $ngram->{didf}, $ngram->{num_pos}, $ngram->{num_neg}) . "\n";
    }
    return $result;
}

1;
