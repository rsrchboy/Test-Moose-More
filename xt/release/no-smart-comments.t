#!/usr/bin/env perl
#
# This file is part of Test-Moose-More
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

no_smart_comments_in("lib/Test/Moose/More.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/attribute/coerce.t");
no_smart_comments_in("t/check_sugar.t");
no_smart_comments_in("t/does_not_ok.t");
no_smart_comments_in("t/does_ok.t");
no_smart_comments_in("t/has_attribute_ok.t");
no_smart_comments_in("t/has_method_ok.t");
no_smart_comments_in("t/is_anon_ok.t");
no_smart_comments_in("t/is_class_ok.t");
no_smart_comments_in("t/is_immutable_ok.t");
no_smart_comments_in("t/is_not_anon_ok.t");
no_smart_comments_in("t/is_role_ok.t");
no_smart_comments_in("t/meta_ok.t");
no_smart_comments_in("t/requires_method_ok.t");
no_smart_comments_in("t/validate_attribute.t");
no_smart_comments_in("t/validate_attribute/in_roles.t");
no_smart_comments_in("t/validate_class.t");
no_smart_comments_in("t/validate_role/basic.t");
no_smart_comments_in("t/validate_role/compose.t");
no_smart_comments_in("t/validate_thing/sugar.t");
no_smart_comments_in("t/wrapped/in_roles.t");

done_testing();
