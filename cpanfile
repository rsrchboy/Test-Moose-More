requires "Data::OptList" => "0";
requires "Moose::Autobox" => "0";
requires "Moose::Util" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "Scalar::Util" => "0";
requires "Sub::Exporter" => "0";
requires "Syntax::Keyword::Junction" => "0";
requires "Test::Builder" => "0";
requires "Test::Moose" => "0";
requires "Test::More" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "Moose" => "0";
  requires "Moose::Role" => "0";
  requires "TAP::SimpleOutput" => "0";
  requires "Test::Builder::Tester" => "0";
  requires "Test::More" => "0.88";
  requires "blib" => "0";
  requires "namespace::autoclean" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
