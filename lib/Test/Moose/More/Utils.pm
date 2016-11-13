package Test::Moose::More::Utils;

# ABSTRACT: Various utility functions for TMM (and maybe others!)

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => {

    exports => [ qw{
        get_mop_metaclass_for
        known_sugar
    } ],

    groups  => { default  => [':all'] },
};

use Carp 'croak';
use List::Util 1.33 qw( first all );
use Scalar::Util 'blessed';

=func get_mop_metaclass_for $mop => $meta

Given a MOP name (e.g. attribute), rummage through $meta (a metaclass) to reveal the MOP's metaclass.

e.g.

    get_metaclass_for attribute => __PACKAGE__->meta;

=cut

sub get_mop_metaclass_for {
    my ($mop, $meta) = @_;

    # FIXME make this less... bad
    # short-circuit!  Better a special case here than *everywhere* else
    return blessed $meta
        if $mop eq 'class' || $mop eq 'role';

    # this code largely lifted from Moose::Util::MetaRole
    my $attr =
        first { $_ }
        map { $meta->meta->find_attribute_by_name($_) }
        ("${mop}_metaclass", "${mop}_class")
        ;

    croak "Cannot find attribute storing the metaclass for $mop in " . $meta->name
        unless $attr;

    my $read_method = $attr->get_read_method;

    return $meta->$read_method();
}

=func known_sugar

Returns a list of all the known standard Moose sugar (has, extends, etc).

=cut

sub known_sugar () { qw{ has around augment inner before after blessed confess } }

!!42;
__END__

=for :stopwords TMM

=head1 SEE ALSO

L<Moose::Util::MetaRole> -- for much of the "find the metaclass for X mop" code

=cut
