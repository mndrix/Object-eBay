use strict;
use warnings;
use lib qw( /home/michael/clients/jjgames/website/catalyst/lib );
use lib qw( /home/michael/projects/perl/Object-eBay/lib );

use JJG::eBay;
use Object::eBay;
use Object::eBay::User;

Object::eBay->init( JJG::eBay->_ebay_object() );
my $user = Object::eBay::User->new({
    user_id => 'lecternmerchant',
});

my $feedback_private = $user->feedback_private;
my $feedback_score   = $user->feedback_score;

print "feedback private : '$feedback_private'\n";
print "feedback score   : '$feedback_score'\n";
