package Object::eBay;
our $VERSION = '0.0.1';

use Class::Std; {
    use warnings;
    use strict;
    use Carp;
    use Scalar::Util qw( blessed );

    my $net_ebay;           # holds a singleton object
    my %details_for :ATTR;
    my %inputs_for  :ATTR( :get<api_inputs> );  # inputs to the API call

    sub init {
        my ($pkg, $net_ebay_object) = @_;
        croak "init() requires a valid Net::eBay object"
            if !defined $net_ebay_object;
        $net_ebay = $net_ebay_object;
    }

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;

        my $object_details = delete $args_ref->{object_details};
        my $needs_methods = delete $args_ref->{needs_methods} || [];
        $inputs_for{$ident} = $self->_convert_args($args_ref);

        for my $method_name (@$needs_methods) {
            $self->_add_inputs( $self->$method_name(':meta') );
        }

        $details_for{$ident} = $object_details if $object_details;
    }
    sub _convert_args {
        my ($self, $args) = @_;

        my %new_args;
        for my $method_name (keys %$args) {
            my $ebay_name = $self->method_name_to_ebay_name($method_name);
            $new_args{$ebay_name} = $args->{$method_name};
        }

        return \%new_args;
    }
    sub _add_inputs {
        my ($self, $meta) = @_;
        my $ident = ident $self;
        
        # handle each extra input
        for my $input ( grep { /\A[A-Z]/ } keys %$meta ) {
            my $new_value = $meta->{$input};

            # handle conflicts
            # TODO allow conflict resolution to be specified by subclasses
            if ( exists $inputs_for{$ident}{$input} ) {
                my $old_value = $inputs_for{$ident}{$input};
                croak "Conflicting $input: '$old_value' and '$new_value'"
                    if $input ne 'DetailLevel';
                $new_value = 'ReturnAll';
            }

            $inputs_for{$ident}{$input} = $new_value;
        }
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

    
    #########################################################################
    # Usage     : $ebay_name = Object::eBay->method_name_to_ebay_name($name)
    # Purpose   : Convert a method name into an eBay name
    # Returns   : an ebay name equivalent to the given method name
    # Arguments : $name - a method name such as (title or selling_status)
    # Throws    : no exceptions
    # Comments  : none
    # See Also  : n/a
    sub method_name_to_ebay_name {
        my ($pkg, $method_name) = @_;

        my $ebay_name = join('',
            map  { $_ eq 'id' ? uc : ucfirst }
            split(/_/, $method_name)
        );
        return $ebay_name;
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

    #########################################################################
    # Usage     : $details = $self->get_details()
    # Purpose   : Retrieves the details for this object from eBay and caches
    #             the results for later use.
    # Returns   : A hash reference representing the details (this is very
    #             similar to the result returned by Net::eBay::submitRequest
    # Arguments : none
    # Throws    : no exceptions
    # Comments  : none
    # See Also  : n/a
    sub get_details {
        my ($self) = @_;
        my $ident = ident $self;

        # look for a cached copy
        my $details = $details_for{$ident};
        return $details if $details;

        # otherwise, ask eBay for the details
        my $response = $self->ask_ebay(
            $self->api_call(),
            $self->api_inputs(),
        );

        # and cache the response
        return $details_for{$ident} = $response->{ $self->response_field() };
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
                my $value = eval { $self->get_details->{$ebay_name} };
                croak "Can't find '$ebay_name' via ${pkg}::$method_name()"
                    if !defined $value;
                return $value;
            };
        }
    }

    sub complex_attributes {
        my ($pkg, $args) = @_;

        while ( my ($ebay_name, $meta) = each %$args ) {
            no strict 'refs';
            my $method_name = $pkg->ebay_name_to_method_name($ebay_name);
            *{ $pkg . "::$method_name" } = sub {
                my ($self, $args) = @_;

                # return meta info if requested
                return $meta if $args && $args eq ':meta';

                my $value = eval { $self->get_details->{$ebay_name} };
                croak "Can't find '$ebay_name' via ${pkg}::$method_name()"
                    if !defined $value;

                return $value if blessed $value;  # already inflated the value

                # inflate value into an object
                if ( my $class_stub = $meta->{class} ) {
                    my $class = "Object::eBay::$class_stub";
                    $value = eval {
                        eval "require $class";
                        $class->new({ object_details => $value })
                    };
                    croak "Error inflating '$ebay_name': $@\n" if $@;
                    croak "Can't inflate '$ebay_name' via ${pkg}::$method_name()"
                        if !defined $value;
                    $self->get_details->{$ebay_name} = $value;
                    return $value;
                }

                return $value;
            };
        }
    }

    sub api_inputs { $_[0]->get_api_inputs() }
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
    my $item = Object::eBay::Item->new({ item_id => 12345678 });
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

=head2 new

TODO document this.  Remember to mention 'needs_methods'.

=head2 PRIVATE METHODS

The following methods are intended for B<internal> use, but are documented
here to make code maintenance and subclassing easier.  Most users of
Object::eBay will B<never use these methods>.  Instead, proceed to the
documentation about the other Object::eBay classes: L</SEE ALSO>.

=head2 api_inputs

    $res = Object::eBay->ask_ebay(
        $self->api_call(),
        $self->api_inputs(),
    );

This method returns a hash reference containing all the inputs required by
the invocant's API call.   This is used when retrieving the details about an
object which does not yet have any details.

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

=head2 complex_attributes

    __PACKAGE__->complex_attributes({
        Seller => {
            class => 'User',
        },
        Description => {
            DetailLevel => 'ItemReturnDescription',
        },
        WatchCount => {
            IncludeWatchCount => 'true',
        },
    });

This method is called by subclasses of eBay::Object to create methods that map
to attributes of eBay API return values.  The example above will create three
methods: C<seller>, C<description> and C<watch_count>.  The return value of
the C<seller> method will be an L<Object::eBay::User> object.  The return
value of the C<description> and C<watch_count> methods will be non-reference
scalars.

The C<description> method requires that 'DetailLevel' be
'ItemReturnDescription' or higher.  In addition to 'DetailLevel', any API
Input value can be specified (for example 'IncludeWatchCount' in the sample
above).  Object::eBay objects try to be lazy and request as little information
from eBay as possible.  This is done by correlating arguments to
C<complex_attributes> with the value of 'needs_methods' set when calling
L</new>.

The argument to C<complex_attributes> should be a single hash reference.  The
keys of the hash should be eBay attribute names.  The value of each key should
likewise be a hash reference.

For simpler mapping of eBay attributes to method names, see
L</simple_attributes>.

=head2 ebay_name_to_method_name

    $method_name = Object::eBay->ebay_name_to_method_name('SellingStatus')
    # returns 'selling_status'

Converts an eBay name in camelcase to a method name in lowercase with words
separated by underscores.  This method implements the algorithm sketched in
the L</DESCRIPTION> section.

=head2 get_details

    $title = $item->get_details->{Title};

Returns a hash reference containing detailed information about the invocant
object.  This hash reference is a slightly modified version of the hashref
returned by Net::eBay::submitRequest.  Again, this method is intended to be
private.  If you want to access information about an Object::eBay object,
please use an accessor method.  If there is no accessor method for the
information you want, see L</HELPING OUT> for information on how to add the
accessor method and then send me a patch.

=head2 method_name_to_ebay_name

    $ebay_name = Object::eBay->method_name_to_ebay_name('selling_status')
    # returns 'SellingStatus'

Converts a method name with underscores separating words into an ebay name in
camelcase.  This method implements the inverse of the algorithm sketched in
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

=head2 Error inflating '%s': %s

If calling the inflation subroutine defined by a Object::eBay subclass causes
an exception, this exception will be thrown with the original exception
message attached.

=head2 Can't find '%s' via %s

If the API response from eBay does not contain the raw information necessary
to evaluate a method, this exception is thrown.

=head2 Can't inflate '%s' via %s

The result of inflating an attribute into an object was an undefined value.
 
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

=head1 HELPING OUT

If you have any patches, please submit them through the RT bug tracking
interface see L</BUGS AND LIMITATIONS>.  Right now, the most needed assistance
is with filling out the objects and associated accessor methods.  To create a
new Object::eBay subclass to implement an additional class of objects on eBay,
you'll need to implement the following methods.  Take a look at
L<Object::eBay::Item> for examples.

=head2 api_call

Override this method so that it returns the name of the eBay API call which
should be invoked to return details about a particular object.  For example,
the L<Object::eBay::Item> class defines this method to return "GetItem"

=head2 response_field

Override this method so that it returns the hash key which accesses all the
important details about a particular object.  For example, the
L<Object::eBay::Item> class defines this method to return "Item".

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

=head1 SEE ALSO

=over 4

=item * L<Object::eBay::Item>

=item * L<Object::eBay::ListingDetails>

=item * L<Object::eBay::SellingStatus>

=item * L<Object::eBay::User>

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
 
