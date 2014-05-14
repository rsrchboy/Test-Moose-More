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
BEGIN {
  $Test::Moose::More::AUTHORITY = 'cpan:RSRCHBOY';
}
# git description: 0.023-1-g4eafdbb
$Test::Moose::More::VERSION = '0.024';

# ABSTRACT: More tools for testing Moose packages

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw{
        is_role is_class
        is_anon is_not_anon
        has_method_ok
        requires_method_ok
        check_sugar_ok check_sugar_removed_ok
        has_attribute_ok
        attribute_options_ok
        validate_attribute
        validate_class validate_role
        meta_ok does_ok does_not_ok
        with_immutable
    } ],
    groups  => { default => [ ':all' ] },
};

use Test::Builder;
use Test::More;
use Test::Moose 'with_immutable';
use Scalar::Util 'blessed';
use Syntax::Keyword::Junction 'any';
use Moose::Autobox;
use Moose::Util 'does_role', 'find_meta';
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


sub is_anon {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is anonymous';

    return $tb->ok(!!$thing_meta->is_anon, $message);
}

sub is_not_anon {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is not anonymous';

    return $tb->ok(!$thing_meta->is_anon, $message);
}


sub known_sugar { qw{ has around augment inner before after blessed confess } }

sub check_sugar_removed_ok {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok(!$t->can($_) => "$t cannot $_") for known_sugar;

    return;
}


sub check_sugar_ok {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok($t->can($_) => "$t can $_") for known_sugar;

    return;
}



sub validate_thing {
    my ($thing, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ### anonymous...
    $args{anonymous} ? is_anon $thing : is_not_anon $thing
        if exists $args{anonymous};

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
                $tb->subtest("[subtest] checking $THING_NAME" => sub {
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
    return unless is_class $class;

    my $name = ref $class || $class;
    do { ok($class->isa($_), "$name isa $_") for @{$args{isa}} }
        if exists $args{isa};

    return validate_thing $class => %args;
}

sub validate_role {
    my ($role, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_role $role;

    requires_method_ok($role => @{ $args{required_methods} })
        if defined $args{required_methods};

    return validate_thing $role => %args;
}



sub validate_attribute {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    has_attribute_ok($thing, $name);
    my $att = find_meta($thing)->get_attribute($name)
        or return;

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

    ### %thing_opts
    validate_class $att => %thing_opts
        if keys %thing_opts;

    return _attribute_options_ok($att, %opts);
}

sub attribute_options_ok {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    has_attribute_ok($thing, $name);
    my $att = find_meta($thing)->get_attribute($name)
        or return;

    return _attribute_options_ok($att, %opts);
}

sub _attribute_options_ok {
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

    my $check = sub {
        my $property = shift || $_;
        my $value    = delete $opts{$property};
        my $has      = "has_$property";

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

=for :stopwords Chris Weyl Karen Etheridge

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Test::Moose::More - More tools for testing Moose packages

=head1 VERSION

This document describes version 0.024 of Test::Moose::More - released May 14, 2014 as part of Test-Moose-More.

=head1 SYNOPSIS

    use Test::Moose::More;

    is_class 'Some::Class';
    is_role  'Some::Role';
    has_method_ok 'Some::Class', 'foo';

    # ... etc

=head1 DESCRIPTION

This package contains a number of additional tests that can be employed
against Moose classes/roles.  It is intended to replace L<Test::Moose> in your
tests, and re-exports any tests that it has and we do not, yet.

=head1 FUNCTIONS

=head2 known_sugar

Returns a list of all the known standard Moose sugar (has, extends, etc).

=head1 TEST_FUNCTIONS

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

=head2 requires_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing requires the methods named in
@methods.

Note that this really only makes sense if $thing is a role.

=head2 is_role $thing

Passes if $thing's metaclass is a L<Moose::Meta::Role>.

=head2 is_class $thing

Passes if $thing's metaclass is a L<Moose::Meta::Class>.

=head2 is_anon $thing

Passes if $thing is "anonymous".

=head2 is_not_anon $thing

Passes if $thing is not "anonymous".

=head2 check_sugar_removed_ok $thing

Ensures that all the standard Moose sugar is no longer directly callable on a
given package.

=head2 check_sugar_ok $thing

Checks and makes sure a class/etc can still do all the standard Moose sugar.

=head2 validate_thing

Runs a bunch of tests against the given C<$thing>, as defined:

    validate_class $thing => (

        attributes => [ ... ],
        methods    => [ ... ],
        isa        => [ ... ],

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],
    );

C<$thing> can be the name of a role or class, an object instance, or a
metaclass.

=head2 validate_role

The same as validate_thing(), but ensures C<$thing> is a role, and allows for
additional role-specific tests.

    validate_role $thing => (

        required_methods => [ ... ],

        # ...and all other options from validate_thing()

=head2 validate_class

The same as validate_thing(), but ensures C<$thing> is a class, and allows for
additional class-specific tests.

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
        -does => [ 'TestRole' ],
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

Not yet documented or tested exhaustively; please see t/validate_attribute.t
for details at the moment.  This test routine is likely to change in
implementation and scope, with every effort to maintain backwards
compatibility.

=head2 attribute_options_ok

Validates that an attribute is set up as expected; like validate_attribute(),
but only concerns itself with attribute options.

Not yet documented or tested exhaustively; please see t/validate_attribute.t
for details at the moment.  This test routine is likely to change in
implementation and scope, with every effort to maintain backwards
compatibility.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Moose>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/Test-Moose-More>
and may be cloned from L<git://https://github.com/RsrchBoy/Test-Moose-More.git>

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

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-Moose-More&title=RsrchBoy's%20CPAN%20Test-Moose-More&tags=%22RsrchBoy's%20Test-Moose-More%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2FTest-Moose-More&title=RsrchBoy's%20CPAN%20Test-Moose-More&tags=%22RsrchBoy's%20Test-Moose-More%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 CONTRIBUTOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
