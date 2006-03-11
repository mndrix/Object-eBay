use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Object::eBay',
    license             => 'perl',
    dist_version_from   => 'lib/Object/eBay.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Object-eBay-*' ],
);

$builder->create_build_script();
