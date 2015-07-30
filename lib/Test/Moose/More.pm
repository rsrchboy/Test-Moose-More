#
# This file is part of Test-Moose-More
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Test::Moose::More;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.032-4-gb24c8bf
$Test::Moose::More::VERSION = '0.033';

# ABSTRACT: More tools for testing Moose packages

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => {
    exports => [ qw{
        attribute_options_ok
        check_sugar_ok
        check_sugar_removed_ok
        does_not_ok
        does_ok
        has_attribute_ok
        has_method_ok
        is_anon_ok
        is_class_ok
        is_immutable_ok
        is_not_anon_ok
        is_not_immutable_ok
        is_role_ok
        meta_ok
        requires_method_ok
        validate_attribute
        validate_class
        validate_role
        validate_thing
        with_immutable

        role_wraps_around_method_ok
        role_wraps_before_method_ok
        role_wraps_after_method_ok

        is_anon
        is_class
        is_not_anon
        is_role
    } ],
    groups  => { default => [ ':all' ] },
};

use Test::Builder;
use Test::More;
use Test::Moose 'with_immutable';
use Scalar::Util 'blessed';
use Syntax::Keyword::Junction 'any';
use Moose::Util 'resolve_metatrait_alias', 'does_role', 'find_meta';
use Moose::Util::TypeConstraints;
use Data::OptList;

# debugging...
#use Smart::Comments;

my $tb = Test::Builder->new();

our $THING_NAME;

sub _thing_name {
    my ($thing, $thing_meta) = @_;

    return $THING_NAME if $THING_NAME;

    $thing_meta ||= find_meta($thing);

    # try very hard to come up with a meaningful name
    my $desc
        = !!$thing_meta  ? $thing_meta->name
        : blessed $thing ? ref $thing
        : ref $thing     ? 'The object'
        :                  $thing
        ;

    return $desc;
}


sub meta_ok ($;$) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' has a meta';

    return $tb->ok(!!$thing_meta, $message);
}


sub does_ok {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does %s';

    $tb->ok(!!$thing_meta->does_role($_), sprintf($message, $_))
        for @$roles;

    return;
}


sub does_not_ok {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does not do %s';

    $tb->ok(!$thing_meta->does_role($_), sprintf($message, $_))
        for @$roles;

    return;
}


# helper to dig for an attribute
sub _find_attribute {
    my ($thing, $attr_name) = @_;

    my $meta = find_meta($thing);

    # if $thing is a role, find_attribute_by_name() is not available to us
    return $meta->isa('Moose::Meta::Role')
        ? $meta->get_attribute($attr_name)
        : $meta->find_attribute_by_name($attr_name)
        ;
}

sub has_attribute_ok ($$;$) {
    my ($thing, $attr_name, $message) = @_;

    my $meta       = find_meta($thing);
    my $thing_name = $meta->name;
    $message     ||= "$thing_name has an attribute named $attr_name";

    return $tb->ok(!!_find_attribute($thing => $attr_name), $message);
}


sub has_method_ok {
    my ($thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    ### @methods
    $tb->ok(!!$meta->has_method($_), "$name has method $_")
        for @methods;

    return;
}


sub role_wraps_around_method_ok { unshift @_, 'around'; goto \&_role_wraps }
sub role_wraps_before_method_ok { unshift @_, 'before'; goto \&_role_wraps }
sub role_wraps_after_method_ok  { unshift @_, 'after';  goto \&_role_wraps }

sub _role_wraps {
    my ($style, $thing, @methods) = @_;

    my $meta_method = "get_${style}_method_modifiers";

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    ### @methods
    $tb->ok(!!$meta->$meta_method($_), "$name wraps $style method $_")
        for @methods;

    return;
}


sub requires_method_ok {
    my ($thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    ### @methods
    $tb->ok(!!$meta->requires_method($_), "$name requires method $_")
        for @methods;

    return;
}


sub is_immutable_ok {
    my ($thing) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    return $tb->ok($meta->is_immutable, "$name is immutable");
}

sub is_not_immutable_ok {
    my ($thing) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    return $tb->ok(!$meta->is_immutable, "$name is not immutable");
}


# NOTE: deprecate at some point late 2015
sub is_role  { goto \&is_role_ok  }
sub is_class { goto \&is_class_ok }

sub is_role_ok  { unshift @_, 'Role';  goto \&_is_moosey_ok }
sub is_class_ok { unshift @_, 'Class'; goto \&_is_moosey_ok }

sub _is_moosey_ok {
    my ($type, $thing) =  @_;

    my $thing_name = ref $thing || $thing;

    my $meta = find_meta($thing);
    $tb->ok(!!$meta, "$thing_name has a metaclass");
    return unless !!$meta;

    return $tb->ok($meta->isa("Moose::Meta::$type"), "$thing_name is a Moose " . lc $type);
}


# NOTE: deprecate at some point late 2015
sub is_anon     { goto \&is_anon_ok     }
sub is_not_anon { goto \&is_not_anon_ok }

sub is_anon_ok {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is anonymous';

    return $tb->ok(!!$thing_meta->is_anon, $message);
}

sub is_not_anon_ok {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is not anonymous';

    return $tb->ok(!$thing_meta->is_anon, $message);
}


sub known_sugar() { qw{ has around augment inner before after blessed confess } }

sub check_sugar_removed_ok($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok(!$t->can($_) => "$t cannot $_") for known_sugar;

    return;
}


sub check_sugar_ok($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok($t->can($_) => "$t can $_") for known_sugar;

    return;
}



sub validate_thing {
    my ($thing, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ### anonymous...
    $args{anonymous} ? is_anon_ok $thing : is_not_anon_ok $thing
        if exists $args{anonymous};

    ### sugar checking...
    $args{sugar} ? check_sugar_ok $thing : check_sugar_removed_ok $thing
        if exists $args{sugar};

    ### roles...
    do { does_ok($thing, $_) for @{$args{does}} }
        if exists $args{does};
    do { does_not_ok($thing, $_) for @{$args{does_not}} }
        if exists $args{does_not};

    ### methods...
    do { has_method_ok($thing, $_) for @{$args{methods}} }
        if exists $args{methods};

    ### attributes...
    ATTRIBUTE_LOOP:
    for my $attribute (@{Data::OptList::mkopt($args{attributes} || [])}) {

        my ($name, $opts) = @$attribute;
        has_attribute_ok($thing, $name);

        if ($opts && (my $att = find_meta($thing)->get_attribute($name))) {

            SKIP: {
                skip 'Cannot examine attribute metaclass in roles', 1
                    if (find_meta($thing)->isa('Moose::Meta::Role'));

                local $THING_NAME = "${thing}'s attribute $name";
                $tb->subtest("checking $THING_NAME" => sub {
                    _validate_attribute($att, %$opts);
                });
            }
        }
    }

    return;
}

sub validate_class {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_class_ok $class;

    my $name = ref $class || $class;
    do { ok($class->isa($_), "$name isa $_") for @{$args{isa}} }
        if exists $args{isa};

    # check our mutability
    do { is_immutable_ok $class }
        if exists $args{immutable} && $args{immutable};
    do { is_not_immutable_ok $class }
        if exists $args{immutable} && !$args{immutable};

    return validate_thing $class => %args;
}

sub validate_role {
    my ($role, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # basic role validation
    return unless is_role_ok $role;
    requires_method_ok($role => @{ $args{required_methods} })
        if defined $args{required_methods};
    $args{-compose}
        ?        validate_thing $role => %args
        : return validate_thing $role => %args
        ;

    # compose it and validate that class.
    my $anon = Moose::Meta::Class->create_anon_class(
        roles => [$role],
        methods => { map { $_ => sub {} } @{ $args{required_methods} || [] } },
    );

    # take anything in required_methods and put it in methods for this test
    $args{methods}
        = defined $args{methods}
        ? [ @{$args{methods}}, @{$args{required_methods} || []} ]
        : [ @{$args{required_methods}                    || []} ]
        ;
    delete $args{required_methods};
    # and add a test for the role we're actually testing...
    $args{does} = [ $role, @{ $args{does} || [] } ];

    # aaaand a subtest wrapper to make it easier to read...
    return $tb->subtest('role composed into ' . $anon->name
        => sub { validate_class $anon->name => %args },
    );
}



sub validate_attribute {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    return _validate_attribute($att, %opts);
}

sub _validate_attribute {
    my ($att, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %thing_opts =
        map  { $_ => delete $opts{"-$_"} }
        map  { s/^-//; $_                }
        grep { /^-/                      }
        sort keys %opts
        ;

    $thing_opts{does} = [ map { resolve_metatrait_alias(Attribute => $_) } @{$thing_opts{does}} ]
        if $thing_opts{does};

    ### %thing_opts
    validate_class $att => %thing_opts
        if keys %thing_opts;

    return _attribute_options_ok($att, %opts);
}

sub attribute_options_ok {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    return _attribute_options_ok($att, %opts);
}

sub _attribute_options_ok {
    my ($att, %opts) = @_;

    goto \&_role_attribute_options_ok
        if $att->isa('Moose::Meta::Role::Attribute');
    goto \&_class_attribute_options_ok;
}

sub _role_attribute_options_ok {
    my ($att, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name                    = $att->name;
    my $thing_name              = _thing_name($name, $att);

    # this much works, at least
    if (exists $opts{coerce}) {

        delete $opts{coerce}
            ? ok( $att->should_coerce, "$thing_name should coerce")
            : ok(!$att->should_coerce, "$thing_name should not coerce")
            ;
    }

    ### for now, skip role attributes: blessed $att
    return $tb->skip('cannot yet test role attribute layouts')
        if keys %opts;
}

sub _class_attribute_options_ok {
    my ($att, %opts) = @_;

    ### for now, skip role attributes: blessed $att
    return $tb->skip('cannot yet test role attribute layouts')
        if $att->isa('Moose::Meta::Role::Attribute');

    my @check_opts =
        qw{ reader writer accessor predicate default builder clearer };
    my @unhandled_opts = qw{ isa does handles traits };

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name = $att->name;

    my $thing_name = _thing_name($name, $att);

    # XXX do we really want to do this?
    if (my $is = delete $opts{is}) {
        $opts{accessor} = $name if $is eq 'rw' && ! exists $opts{accessor};
        $opts{reader}   = $name if $is eq 'ro' && ! exists $opts{reader};
    }

    # helper to check an attribute option we expect to be a string, !exist, or
    # undef
    my $check = sub {
        my $property = shift || $_;
        my $value    = delete $opts{$property};
        my $has      = "has_$property";

        # deeper and deeper down the rabbit hole...
        local $Test::Builder::Level = $Test::Builder::Level + 1;

        defined $value
            ? ok($att->$has,  "$thing_name has a $property")
            : ok(!$att->$has, "$thing_name does not have a $property")
            ;
        is($att->$property, $value, "$thing_name option $property correct")
    };

    if (my $is_required = delete $opts{required}) {

        $is_required
            ? ok($att->is_required,  "$thing_name is required")
            : ok(!$att->is_required, "$thing_name is not required")
            ;
    }

    $check->($_) for grep { any(@check_opts) eq $_ } sort keys %opts;

    do { $tb->skip("cannot test '$_' options yet", 1); delete $opts{$_} }
        for grep { exists $opts{$_} } @unhandled_opts;

    if (exists $opts{init_arg}) {

        $opts{init_arg}
            ?  $check->('init_arg')
            : ok(!$att->has_init_arg, "$thing_name has no init_arg")
            ;
        delete $opts{init_arg};
    }

    if (exists $opts{lazy}) {

        delete $opts{lazy}
            ? ok($att->is_lazy,  "$thing_name is lazy")
            : ok(!$att->is_lazy, "$thing_name is not lazy")
            ;
    }

    if (exists $opts{coerce}) {

        delete $opts{coerce}
            ? ok( $att->should_coerce, "$thing_name should coerce")
            : ok(!$att->should_coerce, "$thing_name should not coerce")
            ;
    }

    for my $opt (sort keys %opts) {

        do { fail "unknown attribute option: $opt"; next }
            unless $att->meta->find_attribute_by_name($opt);

        $check->($opt);
    }

    #fail "unknown attribute option: $_"
        #for sort keys %opts;

    return;
}

1;

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Chad Etheridge Granum Karen

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Test::Moose::More - More tools for testing Moose packages

=head1 VERSION

This document describes version 0.033 of Test::Moose::More - released July 29, 2015 as part of Test-Moose-More.

=head1 SYNOPSIS

    use Test::Moose::More;

    is_class_ok 'Some::Class';
    is_role_ok  'Some::Role';
    has_method_ok 'Some::Class', 'foo';

    # ... etc

=head1 DESCRIPTION

This package contains a number of additional tests that can be employed
against Moose classes/roles.  It is intended to replace L<Test::Moose> in your
tests, and re-exports any tests that it has and we do not, yet.

=head1 FUNCTIONS

=head2 known_sugar

Returns a list of all the known standard Moose sugar (has, extends, etc).

=head1 TEST FUNCTIONS

=head2 meta_ok $thing

Tests $thing to see if it has a metaclass; $thing may be the class name or
instance of the class you wish to check.

=head2 does_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if $thing does the given roles.  $thing may be the class name or
instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=head2 does_not_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if $thing does not do the given roles.  $thing may be the class
name or instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=head2 has_attribute_ok $thing, $attribute_name, [ $message ]

Checks C<$thing> for an attribute named C<$attribute_name>; C<$thing> may be a
class name, instance, or role name.

=head2 has_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing has the methods named in @methods.

=head2 role_wraps_around_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an around method modifier.

=head2 role_wraps_before_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an before method modifier.

=head2 role_wraps_after_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an after method modifier.

=head2 requires_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing requires the methods named in
@methods.

Note that this really only makes sense if $thing is a role.

=head2 is_immutable_ok $thing

Passes if $thing is immutable.

=head2 is_not_immutable_ok $thing

Passes if $thing is not immutable; that is, is mutable.

=head2 is_role_ok $thing

Passes if $thing's metaclass is a L<Moose::Meta::Role>.

=head2 is_class_ok $thing

Passes if $thing's metaclass is a L<Moose::Meta::Class>.

=head2 is_anon_ok $thing

Passes if $thing is "anonymous".

=head2 is_not_anon_ok $thing

Passes if $thing is not "anonymous".

=head2 check_sugar_removed_ok $thing

Ensures that all the standard Moose sugar is no longer directly callable on a
given package.

=head2 check_sugar_ok $thing

Checks and makes sure a class/etc can still do all the standard Moose sugar.

=head2 validate_thing

Runs a bunch of tests against the given C<$thing>, as defined:

    validate_thing $thing => (

        attributes => [ ... ],
        methods    => [ ... ],
        isa        => [ ... ],

        # ensures sugar is/is-not present
        sugar      => 0,

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],
    );

C<$thing> can be the name of a role or class, an object instance, or a
metaclass.

=over 4

=item *

isa => [ ... ]

A list of superclasses thing should have.

=item *

anonymous => 0|1

Check to see if the class is/isn't anonymous.

=item *

does => [ ... ]

A list of roles the thing should do.

=item *

does_not => [ ... ]

A list of roles the thing should not do.

=item *

attributes => [ ... ]

The attributes list specified here is in the form of a list of names, each optionally
followed by a hashref of options to test the attribute for; this hashref takes the
same arguments L</validate_attribute> does.  e.g.:

    validate_thing $thing => (

        attributes => [
            'foo',
            'bar',
            baz => { is => 'ro', ... },
            'bip',
        ],
    );

=item *

methods => [ ... ]

A list of methods the thing should have.

=item *

sugar => 0|1

Ensure that thing can/cannot do the standard Moose sugar.

=back

=head2 validate_role

The same as validate_thing(), but ensures C<$thing> is a role, and allows for
additional role-specific tests.

    validate_role $thing => (

        required_methods => [ ... ],

        # ...and all other options from validate_thing()
    );

=over 4

=item *

-compose => 0|1

When true, attempt to compose the role into an anonymous class, then use it to
run L</validate_class>.  The options we're given are passed to validate_class()
directly, except that any C<required_methods> entry is removed and its contents
pushed onto C<methods>.  (A stub method for each entry in C<required_methods>
will also be created in the new class.)

e.g.:

    ok 1 - TestRole has a metaclass
    ok 2 - TestRole is a Moose role
    ok 3 - TestRole requires method blargh
    ok 4 - TestRole does TestRole
    ok 5 - TestRole does not do TestRole::Two
    ok 6 - TestRole has method method1
    ok 7 - TestRole has an attribute named bar
        # Subtest: role composed into Moose::Meta::Class::__ANON__::SERIAL::1
        ok 1 - Moose::Meta::Class::__ANON__::SERIAL::1 has a metaclass
        ok 2 - Moose::Meta::Class::__ANON__::SERIAL::1 is a Moose class
        ok 3 - Moose::Meta::Class::__ANON__::SERIAL::1 does TestRole
        ok 4 - Moose::Meta::Class::__ANON__::SERIAL::1 does not do TestRole::Two
        ok 5 - Moose::Meta::Class::__ANON__::SERIAL::1 has method method1
        ok 6 - Moose::Meta::Class::__ANON__::SERIAL::1 has method blargh
        ok 7 - Moose::Meta::Class::__ANON__::SERIAL::1 has an attribute named bar
        1..7
    ok 8 - role composed into Moose::Meta::Class::__ANON__::SERIAL::1
    1..8

=item *

required_methods => [ ... ]

A list of methods the role requires a consuming class to supply.

=back

=head2 validate_class

The same as validate_thing(), but ensures C<$thing> is a class, and allows for
additional class-specific tests.

    validate_class $thing => (

        isa  => [ ... ],

        attributes => [ ... ],
        methods    => [ ... ],
        isa        => [ ... ],

        # ensures sugar is/is-not present
        sugar      => 0,

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],

        # ...and all other options from validate_thing()
    );

=over 4

=item *

immutable => 0|1

Checks the class to see if it is/isn't immutable.

=back

=head2 validate_attribute

validate_attribute() allows you to test how an attribute looks once built and
attached to a class.

Let's say you have an attribute defined like this:

    has foo => (
        traits  => [ 'TestRole' ],
        is      => 'ro',
        isa     => 'Int',
        builder => '_build_foo',
        lazy    => 1,
    );

You can use validate_attribute() to ensure that it's built out in the way you
expect:

    validate_attribute TestClass => foo => (

        # tests the attribute metaclass instance to ensure it does the roles
        -does => [ 'TestRole' ],
        # tests the attribute metaclass instance's inheritance
        -isa  => [ 'Moose::Meta::Attribute' ], # for demonstration's sake

        traits   => [ 'TestRole' ],
        isa      => 'Int',
        does     => 'Bar',
        handles  => { },
        reader   => 'foo',
        builder  => '_build_foo',
        default  => undef,
        init_arg => 'foo',
        lazy     => 1,
        required => undef,
    );

Options passed to validate_attribute() prefixed with '-' test the attribute's metaclass
instance rather than a setting on the attribute; that is, '-does' ensures that the
metaclass does a particular role (e.g. L<MooseX::AttributeShortcuts>), while 'does' tests
the setting of the attribute to require the value do a given role.

=head2 attribute_options_ok

Validates that an attribute is set up as expected; like validate_attribute(),
but only concerns itself with attribute options.

Note that some of these options will skip if used against attributes defined in a role.

=over 4

=item *

is => ro|rw

Tests for reader/writer options set as one would expect.

=item *

isa => ...

Validates that the attribute requires its value to be a given type.

=item *

does => ...

Validates that the attribute requires its value to do a given role.

=item *

builder => '...'

Validates that the attribute expects the method name given to be its builder.

=item *

default => ...

Validates that the attribute has the given default.

=item *

init_arg => '...'

Validates that the attribute has the given initial argument name.

=item *

lazy => 0|1

Validates that the attribute is/isn't lazy.

=item *

required => 0|1

Validates that setting the attribute's value is/isn't required.

=back

=for Pod::Coverage is_anon is_class is_not_anon is_role

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Moose>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/Test-Moose-More/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-Moose-More&title=RsrchBoy's%20CPAN%20Test-Moose-More&tags=%22RsrchBoy's%20Test-Moose-More%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-Moose-More&title=RsrchBoy's%20CPAN%20Test-Moose-More&tags=%22RsrchBoy's%20Test-Moose-More%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 CONTRIBUTORS

=for stopwords Chad Granum Karen Etheridge

=over 4

=item *

Chad Granum <chad.granum@dreamhost.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
