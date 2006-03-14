use strict;
use warnings;
use lib qw( /home/michael/clients/jjgames/website/catalyst/lib );
use lib qw( /home/michael/projects/perl/Object-eBay/lib );

use JJG::eBay;
use Object::eBay;
use Object::eBay::Item;

my $item_id = shift @ARGV;

Object::eBay->init( JJG::eBay->_ebay_object() );
my $item = Object::eBay::Item->new({
    item_id       => $item_id,
    #needs_methods => [qw( description watch_count )],
});

my $title       = $item->title;
my $quantity    = $item->quantity;
my $country     = $item->country;
#my $description = $item->description;
#my $watch_count = $item->watch_count;
my $rating_private = $item->seller->feedback_private;
my $seller_rating = $item->seller->feedback_score;
my $current_price = $item->selling_status->current_price;
my $converted_price = $item->selling_status->converted_current_price;
my $end_time    = $item->listing_details->end_time;
my @images      = $item->pictures;

print "title       : '$title'\n";
print "quantity    : '$quantity'\n";
print "country     : '$country'\n";
#print "watch count : '$watch_count'\n";
print "rating private: $rating_private\n";
print "rating is private\n" if $rating_private;
print "rating is public\n" if !$rating_private;
print "seller rating : '$seller_rating'\n";
print "current price : '$current_price' - ", 0+$current_price, "\n";
print "converted price : '$converted_price' - ", 0+$converted_price, "\n";
print "end time    : '$end_time'\n";
print "Image: $_\n" for @images;
#print "description: '$description'\n";
