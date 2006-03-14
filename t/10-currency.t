use strict;
use warnings;
use Test::More tests => 3;
use Object::eBay::Currency;

{
    my $c = Object::eBay::Currency->new({
        object_details => {
            content => 123,
            currencyID => 'USD',
        }
    });
    is( "$c", 'USD123', 'string context' );
    cmp_ok( $c, '==', 123, 'numeric context' );
}

eval {
    Object::eBay::Currency->new({ nothing => 123 });
};
like( $@, qr{Missing 'content' and/or 'currencyID'}, 'invalid construction' );
