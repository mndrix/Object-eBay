package Object::eBay::Item;
our $VERSION = '0.0.1';

use Class::Std; {
    use warnings;
    use strict;
    use base qw( Object::eBay );

    sub api_call       { "GetItem" };
    sub response_field { "Item"    };

    __PACKAGE__->simple_attributes(qw{
        Country
        Title
        Quantity
    });

    __PACKAGE__->complex_attributes({
        Seller => {
            class => 'User',
        },
        SellingStatus => {
            class => 'SellingStatus',
        },
        ListingDetails => {
            class => 'ListingDetails',
        },
        Description => {
            DetailLevel => 'ItemReturnDescription',
        },
        WatchCount => {
            IncludeWatchCount => 'true',
        },
    });
}

1;

__END__

=head1 NAME
 
Object::eBay::Item - Represents an item listed on eBay
 
 
=head1 VERSION
 
This documentation refers to Object::eBay::Item version 0.0.1
 
 
=head1 SYNOPSIS

    use Object::eBay;
    use Object::eBay::Item;

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.) 


=head1 SUBROUTINES/METHODS 

A separate section listing the public components of the module's interface. 
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the 
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each 
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::Item requires no configuration files or environment variables.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for 
system or program resources, or due to internal limitations of Perl 
(for example, many modules that use source code filters are mutually 
incompatible).


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay-item at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-eBay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::eBay

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-eBay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-eBay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-eBay>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-eBay>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
