package Test::Moose::More;

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
    groups => {
        default  => [ ':all' ],
        validate => [ map { "validate_$_" } qw{ attribute class role thing } ],
    },
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

=test meta_ok $thing

Tests $thing to see if it has a metaclass; $thing may be the class name or
instance of the class you wish to check.

=cut

sub meta_ok ($;$) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' has a meta';

    return $tb->ok(!!$thing_meta, $message);
}

=test does_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if $thing does the given roles.  $thing may be the class name or
instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=cut

sub does_ok ($$;$) {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does %s';

    # this generally happens when we're checking a vanilla attribute
    # metaclass, which turns out to be a
    # Class::MOP::Class::Immutable::Class::MOP::Class.  If our metaclass does
    # not have a does_role() method, then by definition the metaclass cannot
    # do the role (that is, it's a Class::MOP metaclass).
    my $_does = $thing_meta->can('does_role') || sub { 0 };

    BEGIN { warnings::unimport 'redundant' if $^V gt v5.21.1 }
    $tb->ok(!!$thing_meta->$_does($_), sprintf($message, $_))
        for @$roles;

    return;
}

=test does_not_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if $thing does not do the given roles.  $thing may be the class
name or instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=cut

sub does_not_ok ($$;$) {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does not do %s';

    my $_does = $thing_meta->can('does_role') || sub { 0 };

    BEGIN { warnings::unimport 'redundant' if $^V gt v5.21.1 }
    $tb->ok(!$thing_meta->$_does($_), sprintf($message, $_))
        for @$roles;

    return;
}

=test has_attribute_ok $thing, $attribute_name, [ $message ]

Checks C<$thing> for an attribute named C<$attribute_name>; C<$thing> may be a
class name, instance, or role name.

=cut

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

    $message ||= _thing_name($thing) . " has an attribute named $attr_name";
    return $tb->ok(!!_find_attribute($thing => $attr_name), $message);
}

=test has_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing has the methods named in @methods.

=cut

sub has_method_ok ($@) {
    my ($thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    ### @methods
    $tb->ok(!!$meta->has_method($_), "$name has method $_")
        for @methods;

    return;
}

=test role_wraps_around_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an around method modifier.

=test role_wraps_before_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an before method modifier.

=test role_wraps_after_method_ok $role, @methods

Queries $role's metaclass to see if $role wraps the methods named in
@methods with an after method modifier.

=cut

sub role_wraps_around_method_ok ($@) { unshift @_, 'around'; goto \&_role_wraps }
sub role_wraps_before_method_ok ($@) { unshift @_, 'before'; goto \&_role_wraps }
sub role_wraps_after_method_ok  ($@) { unshift @_, 'after';  goto \&_role_wraps }

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

=test requires_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing requires the methods named in
@methods.

Note that this really only makes sense if $thing is a role.

=cut

sub requires_method_ok ($@) {
    my ($thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    ### @methods
    $tb->ok(!!$meta->requires_method($_), "$name requires method $_")
        for @methods;

    return;
}

=test is_immutable_ok $thing

Passes if $thing is immutable.

=test is_not_immutable_ok $thing

Passes if $thing is not immutable; that is, is mutable.

=cut

sub is_immutable_ok ($;$) {
    my ($thing, $message) = @_;

    ### $thing
    my $meta = find_meta($thing);

    $message ||= _thing_name($thing, $meta) . ' is immutable';
    return $tb->ok($meta->is_immutable, $message);
}

sub is_not_immutable_ok ($;$) {
    my ($thing, $message) = @_;

    ### $thing
    my $meta = find_meta($thing);

    $message ||= _thing_name($thing, $meta) . ' is not immutable';
    return $tb->ok(!$meta->is_immutable, $message);
}

=test is_role_ok $thing

Passes if $thing's metaclass is a L<Moose::Meta::Role>.

=test is_class_ok $thing

Passes if $thing's metaclass is a L<Moose::Meta::Class>.

=cut

# NOTE: deprecate at some point late 2015
sub is_role  ($) { goto \&is_role_ok  }
sub is_class ($) { goto \&is_class_ok }

sub is_role_ok  ($) { unshift @_, 'Role';  goto \&_is_moosey_ok }
sub is_class_ok ($) { unshift @_, 'Class'; goto \&_is_moosey_ok }

sub _is_moosey_ok {
    my ($type, $thing) =  @_;

    my $thing_name = _thing_name($thing);

    my $meta = find_meta($thing);
    $tb->ok(!!$meta, "$thing_name has a metaclass");
    return unless !!$meta;

    my $is_moosey = $meta->isa("Moose::Meta::$type");

    # special check for class -- this will happen when, say, you're validating
    # an attribute and it's a bog standard Moose::Meta::Attribute: strictly
    # speaking its metaclass is Class::MOPish, but really,
    # a Moose::Meta::Attribute is a Moose class.  Or arguably so.  Certainly
    # in the context of what we're asking about here.  Better approaches to
    # this welcomed as pull requests :)

    $is_moosey ||= ($meta->name || q{}) =~ /^Moose::Meta::/
        if $type eq 'Class';

    return $tb->ok($is_moosey, "$thing_name is a Moose " . lc $type);
}

=test is_anon_ok $thing

Passes if $thing is "anonymous".

=test is_not_anon_ok $thing

Passes if $thing is not "anonymous".

=cut

# NOTE: deprecate at some point late 2015
sub is_anon     ($) { goto \&is_anon_ok     }
sub is_not_anon ($) { goto \&is_not_anon_ok }

sub is_anon_ok ($) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is anonymous';

    return $tb->ok(!!$thing_meta->is_anon, $message);
}

sub is_not_anon_ok ($) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is not anonymous';

    return $tb->ok(!$thing_meta->is_anon, $message);
}

=test check_sugar_removed_ok $thing

Ensures that all the standard Moose sugar is no longer directly callable on a
given package.

=func known_sugar

Returns a list of all the known standard Moose sugar (has, extends, etc).

=cut

sub known_sugar () { qw{ has around augment inner before after blessed confess } }

sub check_sugar_removed_ok ($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok(!$t->can($_) => "$t cannot $_") for known_sugar;

    return;
}

=test check_sugar_ok $thing

Checks and makes sure a class/etc can still do all the standard Moose sugar.

=cut

sub check_sugar_ok ($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok($t->can($_) => "$t can $_") for known_sugar;

    return;
}


=test validate_thing

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

=begin :list

* -subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

* isa => [ ... ]

A list of superclasses thing should have.

* anonymous => 0|1

Check to see if the class is/isn't anonymous.

* does => [ ... ]

A list of roles the thing should do.

* does_not => [ ... ]

A list of roles the thing should not do.

* attributes => [ ... ]

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

* methods => [ ... ]

A list of methods the thing should have.

* sugar => 0|1

Ensure that thing can/cannot do the standard Moose sugar.

=end :list

=test validate_role

The same as validate_thing(), but ensures C<$thing> is a role, and allows for
additional role-specific tests.

    validate_role $thing => (

        required_methods => [ ... ],

        # ...and all other options from validate_thing()
    );

=begin :list

* -compose => 0|1

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

* -subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

* required_methods => [ ... ]

A list of methods the role requires a consuming class to supply.

* before => [ ... ]

A list of methods the role expects to wrap before, on application to a class.

See L<Moose/before> for information on before method modifiers.

* around => [ ... ]

A list of methods the role expects to wrap around, on application to a class.

See L<Moose/around> for information on around method modifiers.

* after => [ ... ]

A list of methods the role expects to wrap after, on application to a class.

See L<Moose/after> for information on after method modifiers.

=end :list

=test validate_class

The same as validate_thing(), but ensures C<$thing> is a class, and allows for
additional class-specific tests.

    validate_class $thing => (

        isa  => [ ... ],

        attributes => [ ... ],
        methods    => [ ... ],

        # ensures sugar is/is-not present
        sugar      => 0,

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],

        # ...and all other options from validate_thing()
    );

=begin :list

* -subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

* immutable => 0|1

Checks the class to see if it is/isn't immutable.

=end :list

=cut

sub validate_thing ($@) { _validate_subtest_wrapper(\&_validate_thing_guts, @_) }
sub validate_class ($@) { _validate_subtest_wrapper(\&_validate_class_guts, @_) }
sub validate_role  ($@) { _validate_subtest_wrapper(\&_validate_role_guts,  @_) }

sub _validate_subtest_wrapper {
    my ($func, $thing, %args) = @_;

    # note incrementing by 2 because of our upper curried function
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    # run tests w/o a subtest wrapper...
    return $func->($thing => %args)
        unless $args{-subtest};

    # ...or with one.
    return $tb->subtest(delete $args{-subtest} => sub { $func->($thing => %args) });
}

sub _validate_thing_guts {
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

                local $THING_NAME = _thing_name($thing) . "'s attribute $name";
                _validate_attribute($att => (
                    -subtest => "checking $THING_NAME",
                    %$opts,
                ));
            }
        }
    }

    return;
}

sub _validate_class_guts {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_class_ok $class;

    my $name = _thing_name($class);
    do { ok($class->isa($_), "$name isa $_") for @{$args{isa}} }
        if exists $args{isa};

    # check our mutability
    do { is_immutable_ok $class }
        if exists $args{immutable} && $args{immutable};
    do { is_not_immutable_ok $class }
        if exists $args{immutable} && !$args{immutable};

    return validate_thing $class => %args;
}

# _validate_role_guts() is where the main logic of validate_role() lives;
# we're broken out here so as to allow it all to be easily wrapped -- or not
# -- in a subtest.

sub _validate_role_guts {
    my ($role, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # basic role validation
    return unless is_role_ok $role;

    requires_method_ok($role => @{ $args{required_methods} })
        if defined $args{required_methods};

    role_wraps_before_method_ok($role => @{ $args{before} })
        if defined $args{before};
    role_wraps_around_method_ok($role => @{ $args{around} })
        if defined $args{around};
    role_wraps_after_method_ok($role => @{ $args{after} })
        if defined $args{after};

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
    return validate_class $anon->name => (
        -subtest => 'role composed into ' . $anon->name,
        %args,
    );
}

=test validate_attribute

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

This function takes all the options L</attribute_options_ok> takes, as well as
the following:

=begin :list

* -subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=end :list

=test attribute_options_ok

Validates that an attribute is set up as expected; like validate_attribute(),
but only concerns itself with attribute options.

Note that some of these options will skip if used against attributes defined in a role.

=begin :list

* -subtest => 'subtest name...'

If set, all tests run (save the first, "does this thing even have this
attribute?" test) will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

* is => ro|rw

Tests for reader/writer options set as one would expect.

* isa => ...

Validates that the attribute requires its value to be a given type.

* does => ...

Validates that the attribute requires its value to do a given role.

* builder => '...'

Validates that the attribute expects the method name given to be its builder.

* default => ...

Validates that the attribute has the given default.

* init_arg => '...'

Validates that the attribute has the given initial argument name.

* lazy => 0|1

Validates that the attribute is/isn't lazy.

* required => 0|1

Validates that setting the attribute's value is/isn't required.

=end :list

=cut

sub _validate_attribute       { _validate_subtest_wrapper(\&__validate_attribute_guts,                 @_) }
sub validate_attribute ($$@)  { _validate_subtest_wrapper( \&_validate_attribute_guts, [shift, shift], @_) }

sub _validate_attribute_guts {
    my ($thingname, %opts) = @_;
    my ($thing, $name) = @$thingname;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    local $THING_NAME = _thing_name($thing) . "'s attribute $name";
    return _validate_attribute($att, %opts);
}

sub __validate_attribute_guts {
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
    {
        # If $THING_NAME is set, we're processing an attribute metaclass via
        # _validate_attribute_guts() or _validate_thing_guts()
        local $THING_NAME = "${THING_NAME}'s metaclass"
            if !!$THING_NAME;
        validate_class $att => %thing_opts
            if keys %thing_opts;
    }

    return _attribute_options_ok($att, %opts);
}

sub attribute_options_ok ($$@) {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    return _validate_subtest_wrapper(\&_attribute_options_ok => ($att, %opts));
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

    exists $opts{required} and delete $opts{required}
        ? ok($att->is_required,  "$thing_name is required")
        : ok(!$att->is_required, "$thing_name is not required")
        ;

    exists $opts{lazy} and delete $opts{lazy}
        ? ok($att->is_lazy,  "$thing_name is lazy")
        : ok(!$att->is_lazy, "$thing_name is not lazy")
        ;

    exists $opts{coerce} and delete $opts{coerce}
        ? ok( $att->should_coerce, "$thing_name should coerce")
        : ok(!$att->should_coerce, "$thing_name should not coerce")
        ;

    ### for now, skip role attributes: blessed $att
    return $tb->skip('cannot yet test role attribute layouts')
        if keys %opts;
}

sub _class_attribute_options_ok {
    my ($att, %opts) = @_;

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

    exists $opts{required} and delete $opts{required}
        ? ok($att->is_required,  "$thing_name is required")
        : ok(!$att->is_required, "$thing_name is not required")
        ;

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

    exists $opts{lazy} and delete $opts{lazy}
        ? ok($att->is_lazy,  "$thing_name is lazy")
        : ok(!$att->is_lazy, "$thing_name is not lazy")
        ;

    exists $opts{coerce} and delete $opts{coerce}
        ? ok( $att->should_coerce, "$thing_name should coerce")
        : ok(!$att->should_coerce, "$thing_name should not coerce")
        ;

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

=for :stopwords subtest

=for Pod::Coverage is_anon is_class is_not_anon is_role

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

=head2 Export Groups

By default, this package exports all test functions.  You can be more
selective, however, and there are a number of export groups (aside from the
default ':all') to help you achieve those dreams!

=begin :list

= :all

All exportable functions.

= :validate

L</validate_attribute>, L</validate_class>, L</validate_role>, L</validate_thing>

=end :list

=head1 SEE ALSO

L<Test::Moose>

=cut
