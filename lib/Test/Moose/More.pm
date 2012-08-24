package Test::Moose::More;

# ABSTRACT: More tools for testing Moose packages

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw{
        is_role is_class
        has_method_ok
        requires_method_ok
        check_sugar_ok check_sugar_removed_ok
        validate_class validate_role
        meta_ok does_ok does_not_ok
        with_immutable
        has_attribute_ok
    } ],
    groups  => { default => [ ':all' ] },
};

use Test::Builder;
use Test::More;
use Test::Moose 'with_immutable';
use Scalar::Util 'blessed';
use Moose::Util 'does_role', 'find_meta';
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

sub does_ok {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does %s';

    $tb->ok(!!$thing_meta->does_role($_), sprintf($message, $_))
        for @$roles;

    return;
}

=test does_not_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if $thing does not do the given roles.  $thing may be the class
name or instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=cut

sub does_not_ok {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does not do %s';

    $tb->ok(!$thing_meta->does_role($_), sprintf($message, $_))
        for @$roles;

    return;
}

=test has_attribute_ok $thing, $attribute_name, [ $message ]

Checks C<$thing> for an attribute named C<$attribute_name>; C<$thing> may be a
class name, instance, or role name.

=cut

sub has_attribute_ok ($$;$) {
    my ($thing, $attr_name, $message) = @_;

    my $meta       = find_meta($thing);
    my $thing_name = $meta->name;
    $message     ||= "$thing_name has an attribute named $attr_name";

    return $tb->ok(($meta->has_attribute($attr_name) ? 1 : 0), $message)
        if $meta->isa('Moose::Meta::Role');

    return $tb->ok(1, $message)
        if $meta->find_attribute_by_name($attr_name);

    return $tb->ok(0, $message);
}

=test has_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing has the methods named in @methods.

=cut

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

=test requires_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing requires the methods named in
@methods.

Note that this really only makes sense if $thing is a role.

=cut

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

=test is_role $thing

Passes if $thing's metaclass is a L<Moose::Meta::Role>.

=test is_class $thing

Passes if $thing's metaclass is a L<Moose::Meta::Class>.

=cut

sub is_role  { unshift @_, 'Role';  goto \&_is_moosey }
sub is_class { unshift @_, 'Class'; goto \&_is_moosey }

sub _is_moosey {
    my ($type, $thing) =  @_;

    my $thing_name = ref $thing || $thing;

    my $meta = find_meta($thing);
    $tb->ok(!!$meta, "$thing_name has a metaclass");
    return unless !!$meta;

    return $tb->ok($meta->isa("Moose::Meta::$type"), "$thing_name is a Moose " . lc $type);
}

=test check_sugar_removed_ok $thing

Ensures that all the standard Moose sugar is no longer directly callable on a
given package.

=func known_sugar

Returns a list of all the known standard Moose sugar (has, extends, etc).

=cut

sub known_sugar { qw{ has around augment inner before after blessed confess } }

sub check_sugar_removed_ok {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok(!$t->can($_) => "$t cannot $_") for known_sugar;

    return;
}

=test check_sugar_ok $thing

Checks and makes sure a class/etc can still do all the standard Moose sugar.

=cut

sub check_sugar_ok {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok($t->can($_) => "$t can $_") for known_sugar;

    return;
}


=test validate_class

validate_class 'Some::Class' => (

    attributes => [ ... ],
    methods    => [ ... ],
    isa        => [ ... ],

    # ensures class does these roles
    does       => [ ... ],

    # ensures class does not do these roles
    does_not   => [ ... ],
);

=test validate_role

The same as validate_class(), but for roles.

=test validate_thing

The same as validate_class() and validate_role(), except without the class or
role validation.

=cut

sub validate_thing {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ### roles...
    do { does_ok($class, $_) for @{$args{does}} }
        if exists $args{does};
    do { does_not_ok($class, $_) for @{$args{does_not}} }
        if exists $args{does_not};

    ### methods...
    do { has_method_ok($class, $_) for @{$args{methods}} }
        if exists $args{methods};

    ### attributes...
    for my $attribute (@{Data::OptList::mkopt($args{attributes} || [])}) {

        my ($name, $opts) = @$attribute;
        has_attribute_ok($class, $name);
        local $THING_NAME = "${class}'s attribute $name";
        validate_thing(find_meta($class)->get_attribute($name), %$opts)
            if $opts;
    }

    return;
}

sub validate_class {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_class $class;

    do { isa_ok($class, $_) for @{$args{isa}} }
        if exists $args{isa};

    return validate_thing $class => %args;
}

sub validate_role {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_role $class;

    return validate_thing $class => %args;
}

!!42;

__END__

=head1 SYNOPSIS

    use Test::Moose::More;

    is_class 'Some::Class';
    is_role  'Some::Role';
    has_method_ok 'Some::Class', 'foo';

    # ... etc

=head1 DESCRIPTION

This package contains a number of additional tests that can be employed
against Moose classes/roles.  It is intended to replace L<Test::Moose> in your
tests, and reexports any tests that it has and we do not, yet.

=head1 SEE ALSO

L<Test::Moose>

=cut
