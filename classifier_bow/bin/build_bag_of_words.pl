#!/usr/bin/perl

use Moose;

my $POS_LABEL = 1;
my $NEG_LABEL = -1;

use Factoid::Classifier::Item;
use Factoid::Classifier::BagOfWords;
use Factoid::Text::Ngrammer qw(get_ngrams);

has 'first_class_input_file' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    traits => ['Getopt'],
);

has 'second_class_input_file' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    traits => ['Getopt'],
);

has 'model_name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    traits => ['Getopt'],
);

sub build_ngrams_from_file {
    my ($self, $file_name, $label_type) = @_;
    
    my @ngrams;
    
    open FH, '<', $file_name;
    my $processed_num = 0;
    while (my $line = <FH>) {
        chomp $line;
        my $item = Factoid::Classifier::Item->new({ text => $line, label => $label_type, type => 'train' });
        push @ngrams, $item->ngrams_with_label;
        print "Processed $processed_num items\n" if $processed_num % 50 == 0;
        $processed_num++;
    }
    close(FH);

    return @ngrams;
}

sub main {
    my $self = shift;
    print "Starting\n";
    
    my @first_class_ngrams = $self->build_ngrams_from_file($self->first_class_input_file, $POS_LABEL);
    my @second_class_ngrams = $self->build_ngrams_from_file($self->second_class_input_file, $NEG_LABEL);
    my @ngrams = (@first_class_ngrams, @second_class_ngrams);
    print "Ngrams loaded\n";

    print "Start building BOW model\n";
    my $model = Factoid::Classifier::BagOfWords->new({ name => $self->model_name });
    $model->build(\@ngrams);
    $model->save;
    print "Finished\n";
}

__PACKAGE__->run_script;
