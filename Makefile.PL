
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "More tools for testing Moose packages",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Moose-More",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Test::Moose::More",
  "PREREQ_PM" => {
    "Data::OptList" => 0,
    "Moose::Autobox" => 0,
    "Moose::Util" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Syntax::Keyword::Junction" => 0,
    "Test::Builder" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "TAP::SimpleOutput" => 0,
    "Test::Builder::Tester" => 0,
    "Test::More" => "0.88",
    "blib" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.020",
  "test" => {
    "TESTS" => "t/*.t t/attribute/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



