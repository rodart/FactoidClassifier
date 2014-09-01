#!/usr/bin/perl

use Moose;

my $POS_LABEL = 1;
my $NEG_LABEL = -1;

use Factoid::Classifier::Item;
use Factoid::Text::Ngrammer qw(get_ngrams);
use Factoid::Classifier::BagOfWords;
use Factoid::Classifier;

use List::Util qw(sum shuffle);

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

has 'portions' => (
    is => 'ro',
    isa => 'Int',
    default => 5,
    traits => ['Getopt'],
);


sub get_items_from_file {
    my ($self, $file_name, $label_type) = @_;   
   
    open FH, '<', $file_name;
    my @items;

    while (my $line = <FH>) {                                                                                                                                                                                
        chomp $line;
        push @items, { text => $line, label => $label_type };
    }    
    close(FH);

    return @items;
}

sub main {
    my $self = shift;
 
    print "Starting\n";

    my @first_class_items = $self->get_items_from_file($self->first_class_input_file, $POS_LABEL);
    my @second_class_items = $self->get_items_from_file($self->second_class_input_file, $NEG_LABEL);
    my @items = (@first_class_items, @second_class_items);
    @items = shuffle @items;

    my @buckets;
    for my $i (0 .. @items - 1) {
        push @{$buckets[$i % $self->portions]}, $items[$i];
    }
    
    my $inc = 0;
    my @results;
    my @undefs;
    for my $current_train_bucket_idx (0 .. $self->portions - 1) {
        my @train_data;
        my @test_data;
        for my $bucket_idx (0 .. $self->portions - 1) {
            if ($bucket_idx != $current_train_bucket_idx) {
                push @train_data, map { Factoid::Classifier::Item->new({ %$_, type => 'train' }) } @{$buckets[$bucket_idx]};
            } else {
                push @test_data, map { Factoid::Classifier::Item->new({ %$_, type => 'test' }) } @{$buckets[$bucket_idx]};
            }
        }

        my @ngrams;
        for my $item (@train_data) {
            push @ngrams, $item->ngrams_with_label;
        }

        my $name = join('.', 'validate', $$, time, $inc++);
        my $model = Factoid::Classifier::BagOfWords->new({ name => $name });
        $model->build(\@ngrams);
    
        my ($total, $undef) = (0.0, 0.0);
        my ($tp, $fp, $fn, $tn) = (0.0, 0.0, 0.0, 0.0);
        my $classifier = Factoid::Classifier->new({ name => $name, bow => $model });
        for my $item (@test_data) {
            $classifier->predict($item);

            ++$tp if $item->label == 1 and $item->predicted_label == 1;
            ++$fp if $item->label == -1 and $item->predicted_label == 1;                                                                                                                                     
            ++$fn if $item->label == 1 and $item->predicted_label == -1;
            ++$tn if $item->label == -1 and $item->predicted_label == -1;
            ++$undef if $item->predicted_label == 0;
            ++$total;
        }

        print "Result for bucket $current_train_bucket_idx:\n";
        print "Model accuracy on test set: " . (($tp + $tn) / ($tp + $fp + $fn + $tn)) . "\n";
        print "Undefined items of test set: " . ($undef / ($tp + $fp + $fn + $tn)) . "\n";
                                                                                                                                                                                                             
        my $precision = $tp / ($tp + $fp);
        my $recall = $tp / ($tp + $fn);
        my $f1 = 2 * ($precision * $recall) / ($precision + $recall);
    
        print "Model quality in test set: precision = $precision, recall = $recall, f1 = $f1\n";
        print "Undef for bucket $current_train_bucket_idx: " . ($undef / $total) . "\n";

        push @results, $f1;
        push @undefs, ($undef / $total);
    }

    print "Results for " . $self->model_name . "\n";
    print "Results: @results\n";
    print "Undefs: @undefs\n"; 
    print "Median result: " . (sum(@results) / scalar(@results)) . "\n";
    print "Median undef: " . (sum(@undefs) / scalar(@undefs)) . "\n";
}

__PACKAGE__->run_script;
