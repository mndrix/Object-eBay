use strict;
use warnings;
use Test::More tests => 5;

use Object::eBay::Boolean;

{
    my $b = Object::eBay::Boolean->new({ object_details => 'true' });
    is( "$b", 'true', 'true: string' );
    ok( $b, 'true: boolean' );
}

{
    my $b = Object::eBay::Boolean->new({ object_details => 'false' });
    is( "$b", 'false', 'false: string' );
    ok( !$b, 'false: boolean' );
}

eval {
    Object::eBay::Boolean->new({ object_details => 'bad value' });
};
like( $@, qr/Invalid boolean value 'bad value'/, 'invalid boolean value' );
