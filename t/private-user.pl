use strict;
use warnings;
use lib qw( /Users/michael/clients/jjgames/git/JJG/lib );

use JJG::eBay;
use Object::eBay;
use Object::eBay::User;

Object::eBay->init( JJG::eBay->_ebay_object() );
my $user = Object::eBay::User->new({
    user_id => 'mndrix',
});

my $feedback_private = $user->is_feedback_private;
my $feedback_score   = $user->feedback_score;

print "feedback private : '$feedback_private'\n";
print "feedback score   : '$feedback_score'\n";
