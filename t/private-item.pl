use strict;
use warnings;
use lib qw( /Users/michael/clients/jjgames/git/JJG/lib );

use JJG::eBay;
use Object::eBay;
use Object::eBay::Item;

my $item_id = shift @ARGV;

Object::eBay->init( JJG::eBay->_ebay_object() );
my $item = Object::eBay::Item->new({
    item_id       => $item_id,
    needs_methods => [qw( attribute_set_array )],
});

my $title       = $item->title;
my $quantity    = $item->quantity;
my $country     = $item->country;
#my $description = $item->description;
#my $watch_count = $item->watch_count;
my $rating_private = $item->seller->is_feedback_private;
my $seller_rating = $item->seller->feedback_score;
my $current_price = $item->selling_status->current_price;
my $converted_price = $item->selling_status->converted_current_price;
my $bin_price = $item->buy_it_now_price;
my $end_time    = $item->listing_details->end_time;
my $start_time    = $item->listing_details->end_time;
my $ended  = $item->is_ended;
my $sold   = $item->selling_status->quantity_sold;
my ($condition) = $item->attributes->find(10244);
my $bin_available    = $item->listing_details->is_buy_it_now_available;
my @images      = $item->pictures;

print "title       : '$title'\n";
printf "bid count   : %d\n", $item->selling_status->bid_count;
print "quantity    : '$quantity'\n";
print "country     : '$country'\n";
#print "watch count : '$watch_count'\n";
print "rating private: $rating_private\n";
print "rating is private\n" if $rating_private;
print "rating is public\n" if !$rating_private;
print "seller rating : '$seller_rating'\n";
printf "seller username : '%s'\n", $item->seller->user_id;
printf "seller email : '%s'\n", $item->seller->email;
print "current price : '$current_price' - ", 0+$current_price, "\n";
print "converted price : '$converted_price' - ", 0+$converted_price, "\n";
print "BIN price : $bin_price\n";
print "BIN available : $bin_available\n";
print "end time    : '$end_time'\n";
print "start time  : '$start_time'\n";
print "ended       : '$ended'\n";
print "sold        : '$sold'\n";
print "high bidder :\n";
printf "  username : '%s'\n", $item->selling_status->high_bidder->user_id;
printf "  email    : '%s'\n", $item->selling_status->high_bidder->email;
print "condition   : '$condition'\n";
print "Image: $_\n" for @images;
#print "description: '$description'\n";
