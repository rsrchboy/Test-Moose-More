use strict;
use warnings;

use v5.10;

use Test::More;
use Test::Moose::More;
use Test::Moose::More::Utils;

{ package TestRole;  use Moose::Role; }
{ package TestClass; use Moose;       }

use Moose::Util::MetaRole;
use List::Util 'uniq';

my @class_metaclass_types = qw{
    class
    attribute
    method
    wrapped_method
    instance
    constructor
    destructor
};
    # error ?!

my @role_metaclass_types = qw{
    role
    attribute
    method
    required_method
    wrapped_method
    conflicting_method
    application_to_class
    application_to_role
    application_to_instance
    applied_attribute
};
    # application_role_summation ?!

my %metaroles =
    map { $_->name => $_                                  }
    map { Moose::Meta::Role->create("MetaRole::$_" => ()) }
    uniq sort @class_metaclass_types, @role_metaclass_types, 'nope'
    ;

say for sort keys %metaroles;

Moose::Util::MetaRole::apply_metaroles for => $_,
    class_metaroles => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    },
    role_metaroles => {
        map { $_ => [ "MetaRole::$_" ] } @role_metaclass_types
    }
    for qw{ TestClass TestRole }
    ;

# say get_mop_metaclass_for($_ => TestClass->meta)
#     for @class_metaclass_types;

subtest 'TestClass via does_metaroles_ok' => sub {
    does_metaroles_ok TestClass => {
        map { $_ => [ "MetaRole::$_" ] } @class_metaclass_types
    };
};

subtest 'TestRole via does__metaroles_ok' => sub {
    does_metaroles_ok TestRole => {
        map { $_ => [ "MetaRole::$_" ] } @role_metaclass_types
    };
};

done_testing;
