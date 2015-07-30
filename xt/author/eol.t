use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

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
    't/is_anon_ok.t',
    't/is_class_ok.t',
    't/is_immutable_ok.t',
    't/is_not_anon_ok.t',
    't/is_role_ok.t',
    't/meta_ok.t',
    't/requires_method_ok.t',
    't/validate_attribute.t',
    't/validate_attribute/in_roles.t',
    't/validate_class.t',
    't/validate_role/basic.t',
    't/validate_role/compose.t',
    't/validate_thing/sugar.t',
    't/wrapped/in_roles.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
