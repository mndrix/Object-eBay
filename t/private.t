use strict;
use warnings;
use lib qw( /home/michael/clients/jjgames/website/catalyst/lib );
use lib qw( /home/michael/projects/perl/Object-eBay/lib );

use JJG::eBay;
use Object::eBay;
use Object::eBay::Item;

Object::eBay->init( JJG::eBay->_ebay_object() );
my $item = Object::eBay::Item->new({ item_id => 8267431549 });

my $title    = $item->title;
my $quantity = $item->quantity;
my $country  = $item->country;

print "title   : '$title'\n";
print "quantity: '$quantity'\n";
print "country : '$country'\n";
