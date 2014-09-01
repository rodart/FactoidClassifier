use strict;
use warnings;

use WWW::Curl::Easy;
use HTML::Strip;                                                                                                                                                                                             
use Lingua::Sentence;

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

sub get_yelp_content {

    my ($type, $pages_num, $reviews_per_page) = @_;

    my $curl = WWW::Curl::Easy->new;
    open my $fh, ">yelp_napkin_$type.txt";
    for (my $cur_page_num = 0; $cur_page_num < $pages_num; $cur_page_num++) {  
        print "$type: cur_page_num = $cur_page_num\n";
        if ($type eq 'recommended') {
            if ($cur_page_num == 0) {
                $curl->setopt(CURLOPT_URL, "http://www.yelp.com/biz/5-napkin-burger-new-york");
            } else {
                $curl->setopt(CURLOPT_URL, "http://www.yelp.com/biz/5-napkin-burger-new-york?start=" . $cur_page_num * $reviews_per_page);
            }
        } else {
            if ($cur_page_num == 0) {
                $curl->setopt(CURLOPT_URL, "http://www.yelp.com/not_recommended_reviews/5-napkin-burger-new-york");
            } else {
                $curl->setopt(CURLOPT_URL, "http://www.yelp.com/not_recommended_reviews/5-napkin-burger-new-york?not_recommended_start=" . $cur_page_num * $reviews_per_page);
            }
        }
        
        my $response_body;
        $curl->setopt(CURLOPT_WRITEDATA, \$response_body);
        my $retcode = $curl->perform;
            
        my $html_pattern;
        if ($type eq 'recommended') {
            $html_pattern = '<p class="review_comment ieSucks" itemprop="description" lang="en">';
        } else {
            $html_pattern = '<p class="review_comment ieSucks" lang="en">';
        }

        my @reviews = $response_body =~ /$html_pattern(.*?)<\/p>/g;

        for my $review (@reviews) {
            $review = get_text_without_html($review);
            my $sentences = get_sentences($review);
            for my $sentence (@$sentences) {
                print $fh "$sentence\n" if $sentence ne 'This review has been removed for violating our Content Guidelines or Terms of Services';
            }
        }
    }
    close($fh);
}

get_yelp_content("recommended", 32, 40);
get_yelp_content("not_recommended", 16, 10);
