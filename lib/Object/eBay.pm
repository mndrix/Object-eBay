package Object::eBay;
our $VERSION = '0.0.1';

use Class::Std; {
    use warnings;
    use strict;
    use Carp;

    my $net_ebay;   # holds a singleton object
    my %details :ATTR( :name<details> );

    sub init {
        my ($pkg, $net_ebay_object) = @_;
        croak "init() requires a valid Net::eBay object"
            if !defined $net_ebay_object;
        $net_ebay = $net_ebay_object;
    }

    ##########################################################################
    # Usage     : $method_name = Object::eBay->ebay_name_to_method_name($name)
    # Purpose   : Convert eBay names into method names
    # Returns   : a method name equivalent to the given eBay name
    # Arguments : $name - an eBay name such as (Title or SellingStatus)
    # Throws    : no exceptions
    # Comments  : none
    # See Also  : n/a
    sub ebay_name_to_method_name {
        my ($pkg, $ebay_name) = @_;
        return $ebay_name if !$ebay_name;
        $ebay_name =~ s{
            ([[:lower:]])   # lower case letter
            ([[:upper:]])   # followed by an upper case letter
        }{$1_\l$2}xmsg;
        return lc $ebay_name;
    }

    ##########################################################################
    # Usage     : $result = Object::eBay->ask_ebay(
    #               'GetItem',
    #               { ItemID => 123455678 }
    #             );
    # Purpose   : dispatch an API call to eBay
    # Returns   : a hashref with eBay's response
    # Arguments : $api_call - the name of the eBay API call to make
    #             $inputs   - a hashref giving input fields for the API call
    # Throws    : "Unable to process the command ..."
    #             "eBay error (...): ..."
    # Comments  : throws an error if the API call couldn't be completed or
    #             if eBay returns an error value
    # See Also  : n/a
    sub ask_ebay {
        my ( $class, $command, $arguments ) = @_;

        my $result = $net_ebay->submitRequest( $command, $arguments );
        croak "Unable to process the command $command"
            if !$result;

        if ( exists $result->{Errors} ) {
            my $errors  = $result->{Errors};
            my $code    = $errors->{ErrorCode};
            my $message = $errors->{LongMessage};
            croak "eBay error ($code): $message";
        }

        return $result;
    }

    #############################################################################
    # Usage     : __PACKAGE__->simple_attributes('title', 'quantity')
    # Purpose   : Define simple attributes for an Object::eBay subclass
    # Returns   : none
    # Arguments : a list of method names to implement
    # Throws    : no exceptions
    # Comments  : none
    # See Also  : n/a
    sub simple_attributes {
        my ($pkg, @ebay_names) = @_;

        # install a method for each eBay name
        for my $ebay_name (@ebay_names) {
            no strict 'refs';
            my $method_name = $pkg->ebay_name_to_method_name($ebay_name);
            *{ $pkg . "::$method_name" } = sub {
                my ($self) = @_;
                my $value = $self->get_details->{$ebay_name};
                croak "Can't find $ebay_name via $method_name()"
                    if !defined $value;
                return $value;
            };
        }
    }

    sub complex_attributes {
        # TODO implement me
    }
}

1;

__END__

=head1 NAME
 
Object::eBay - Object-oriented interface to the eBay API
 
 
=head1 VERSION
 
This documentation refers to Object::eBay version 0.0.1
 
 
=head1 SYNOPSIS

    use Object::eBay;
    my $ebay = # ... create a Net::eBay object ...
    Object::eBay->init($ebay);
    my $item = Object::eBay::Item->new({ id => 12345678 });
    print "Item #", $item->auction_number(), " titled '", $item->title(), "'\n"

=head1 DESCRIPTION
 
Object::eBay provides a simple object-oriented interface to the eBay API.
Objects are created to represent entities dealing with eBay such as items,
users, etc.  You won't want to create objects of the class L<Object::eBay> but
rather of its subclasses such as: L<Object::eBay::Item> or
L<Object::eBay::User>.

L<Object::eBay> follows some simple rules to make the names of eBay API
objects more "Perlish."  Namely, for packages, eBay's camelcase is retained.
For example L<Object::eBay::ListingDetails>.  For attribute names, the
camelcase is converted to underscore separated method names with roughly the
following algorithm:

    Before each capital letter after the first one, place an underscore
    Make all letters lowercase

So, eBay's "FeedbackScore" becomes the method name "feedback_score".
Generally, the transformation algorithm does what you'd expect.  Attributes
like "ItemID" become "item_id" as anticipated.
 
=head1 PUBLIC METHODS

The following methods are intended for general use.
 
=head2 init

  Object::eBay->init($net_ebay_object);

Requires a single Net::eBay object as an argument.  This class method must be
called before creating any Object::eBay objects.  The Net::eBay provided to
C<init> object should be initialized and ready to perform eBay API calls.  All
Object::eBay objects will use this Net::eBay object.

=head2 PRIVATE METHODS

The following methods are intended for internal use, but are documented here
to make code maintenance and subclassing easier.  Most users of Object::eBay
will never use these methods.  Instead, proceed to the documentation about the
other Object::eBay classes.

=head2 ask_ebay

    $res = Object::eBay->ask_ebay(
        GetItem => {
            ItemID => 12345678,
            DetailLevel => 'ItemReturnDescription',
        }
    )

A thin wrapper around L<Net::eBay/submitRequest> which performs API calls
using eBay's API and encapsulates error handling.  If an error occurs during
the API call, or eBay returns a result with an error, an exception is thrown.

=head2 ebay_name_to_method_name

    $method_name = Object::eBay->ebay_name_to_method_name('SellingStatus')
    # returns 'selling_status'

Converts an eBay name in camelcase to a method name in lowercase with words
separated by underscores.  This method implements the algorithm sketched in
the L</DESCRIPTION> section.

=head2 simple_attributes

    __PACKAGE__->simple_attributes(qw{ Quantity Title });

This method is called by subclasses of eBay::Object to create methods that map
easily to attributes of eBay API return values.  The example above will create
two methods: C<quantity> and C<title> which return the "Quantity" and "Title"
attributes of the object in question.  The return value of methods created
with C<simple_attributes> will be non-reference scalars.  For more complex
mapping of eBay attributes to method names, see L</complex_attributes>.

=head1 DIAGNOSTICS

=head2 init() requires a valid Net::eBay object

This exception is thrown when L</init> is called without providing a
Net::eBay object as the argument.
 
=head1 CONFIGURATION AND ENVIRONMENT
 
Object::eBay requires no configuration files or environment variables.
However, L<Net::eBay> can make use of configuration files and that is often
easier than including set up information in every program that uses
L<Object::eBay>.
 
=head1 DEPENDENCIES
 
=head2 Net::eBay

=head2 Class::Std
 
=head1 INCOMPATIBILITIES
 
None known.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay at rt.cpan.org>, or through the web interface at
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

Igor Chudov for writing Net::eBay.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
