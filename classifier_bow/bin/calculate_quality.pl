#!/usr/bin/perl

use Moose;

my $POS_LABEL = 1;
my $NEG_LABEL = -1;

use Factoid::Text::Ngrammer qw(get_ngrams);
use Factoid::Classifier::Item;
use Factoid::Classifier;

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

has 'mistakes_dir' => (
    is => 'ro',
    isa => 'Str',
    default => 'predict_mistakes',
    traits => ['Getopt'],
);


sub get_items_from_file {
    my ($self, $file_name, $label_type) = @_;   
   
    open FH, '<', $file_name;
    my @items;

    while (my $line = <FH>) {
        chomp $line;
        push @items, Factoid::Classifier::Item->new({ text => $line, label => $label_type, type => 'test' });
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
    
    print "Items loaded\n";
    
    print scalar(@items) . " items in the test set\n";
    
    my $bow_model = Factoid::Classifier->new({ 
        name => $self->model_name,
    });
    
    my $undef = 0.0;
    my ($tp, $fp, $fn, $tn) = (0.0, 0.0, 0.0, 0.0);
    open MISTAKES_FH, '>', $self->mistakes_dir .  '/' . $self->model_name . '.bad';

    my $processed_num = 0;    
    for my $item (@items) {
        $bow_model->predict($item);
        
        if ($item->predicted_label == 0) {
            $undef++;
        } else {
            if ($item->label != $item->predicted_label) {
                print MISTAKES_FH join("\t", $item->text, $item->label, $item->predicted_label) . "\n";
            }

            ++$tp if $item->label == 1 and $item->predicted_label == 1;
            ++$fp if $item->label == -1 and $item->predicted_label == 1;
            ++$fn if $item->label == 1 and $item->predicted_label == -1;
            ++$tn if $item->label == -1 and $item->predicted_label == -1;
        }
        
        print "Processed $processed_num items\n" if $processed_num % 50 == 0;
        $processed_num++;
    }
    
    print "Model accuracy on test set: " . (($tp + $tn) / ($tp + $fp + $fn + $tn)) . "\n";
    print "Undefined items of test set: " . ($undef / ($tp + $fp + $fn + $tn)) . "\n";
    
    my $precision = $tp / ($tp + $fp);
    my $recall = $tp / ($tp + $fn);
    my $f1 = 2 * ($precision * $recall) / ($precision + $recall);
    
    print "Model quality in test set: precision = $precision, recall = $recall, f1 = $f1\n";
    
    close(MISTAKES_FH);

    print "Finished\n";
}

__PACKAGE__->run_script;
