package Test::Moose::More;

# ABSTRACT: More tools for testing Moose packages

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw{ has_method_ok is_role is_class } ],
    groups  => { default => [ ':all' ] },
};
use Test::Builder;
use Test::More;
use Moose::Util 'does_role', 'find_meta';

# debugging...
#use Smart::Comments;

my $tb = Test::Builder->new();

=function has_method_ok $thing, @methods

Queries $thing's metaclass to see if $thing has the methods named in @methods.

=cut

sub has_method_ok {
    my ($thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = $meta->name;

    ### @methods
    $tb->ok(!!$meta->has_method($_), "$name has method $_") for @methods;
    return;
}

=function is_role $thing

Passes if $thing's metaclass isa L<Moose::Meta::Role>.

=function is_class $thing

Passes if $thing's metaclass isa L<Moose::Meta::Class>.

=cut

sub is_role  { unshift @_, 'Role';  goto \&_is_moosey }
sub is_class { unshift @_, 'Class'; goto \&_is_moosey }

sub _is_moosey {
    my ($type, $thing) =  @_;

    my $thing_name = ref $thing || $thing;

    my $meta = find_meta($thing);
    $tb->ok(!!$meta, "$thing_name has a metaclass");
    return unless !!$meta;

    $tb->ok($meta->isa("Moose::Meta::$type"), "$thing_name is a Moose " . lc $type);
    return;
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
against Moose classes/roles.  It is intended to coexist with L<Test::Moose>,
though it does not (currently) require it.

=head1 SEE ALSO

L<Test::Moose>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.

Bugs, feature requests and pull requests through GitHub are most welcome; our
page and repo (same URI):

    https://github.com/RsrchBoy/test-moose-more

=cut

