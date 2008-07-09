use Test::More tests => 7;

BEGIN {
    use_ok('Object::eBay');
    use_ok('Object::eBay::Attribute');
    use_ok('Object::eBay::Attributes');
    use_ok('Object::eBay::Item');
    use_ok('Object::eBay::User');
    use_ok('Object::eBay::ListingDetails');
    use_ok('Object::eBay::SellingStatus');
}

diag( "Testing Object::eBay $Object::eBay::VERSION" );
