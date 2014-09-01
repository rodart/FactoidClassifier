#!/usr/bin/perl

use Moose;

use Factoid::Text::Ngrammer qw(get_ngrams);
use Factoid::Classifier::Item;
use Factoid::Classifier;

use File::Basename;

has 'input_file' => (
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

sub get_items_from_file {
    my $self = shift;
    
    open FH, '<', $self->input_file;    
    my @items;

    while (my $line = <FH>) {
        chomp $line;
        push @items, Factoid::Classifier::Item->new({ text => $line, type => 'test' });
    }
    close(FH);

    return @items;
}

sub main {
    my $self = shift;
    
    print "Starting\n";
    
    my @items = $self->get_items_from_file();
    
    print "Items loaded\n";
    print scalar(@items) . " items in the test set\n";
    
    my $bow_model = Factoid::Classifier->new({ 
        name => $self->model_name,
    });
    
    my $undef_num = 0;
    open UNDEF_FH, '>', basename($self->input_file) . '.undef';
    open PREDICT_FH, '>', basename($self->input_file) . '.predict';
    
    for my $item (@items) {
        $bow_model->predict($item);
        
        if ($item->predicted_label == 0) {
            $undef_num++;
            print UNDEF_FH $item->text . "\n";
        } else {
            print PREDICT_FH join("\t", $item->text, $item->predicted_label) . "\n";
        }
    }
    
    print "Undefined items of test set: $undef_num\n";
    
    close(UNDEF_FH);
    close(PREDICT_FH);

    print "Finished\n";
}

__PACKAGE__->run_script;
