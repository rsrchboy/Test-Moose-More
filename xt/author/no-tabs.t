use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Moose/More.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/attribute/coerce.t',
    't/check_sugar.t',
    't/does_not_ok.t',
    't/does_ok.t',
    't/has_attribute_ok.t',
    't/has_method_ok.t',
    't/is_anon.t',
    't/is_class.t',
    't/is_not_anon.t',
    't/is_role.t',
    't/meta_ok.t',
    't/requires_method_ok.t',
    't/validate_attribute.t',
    't/validate_class.t',
    't/validate_role.t'
);

notabs_ok($_) foreach @files;
done_testing;
