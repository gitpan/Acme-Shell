use ExtUtils::MakeMaker;

my $prereqs = {
  Error => 0.17015,
  File::HomeDir::Unix => 0.86,
  Lexical::Persistence => 0.98,
  Term::ReadLine => 1.0,
  Test::More => 0.86,
};

WriteMakefile(
  ABSTRACT_FROM => 'lib/Acme/Shell.pm',
  VERSION_FROM  => 'lib/Acme/Shell.pm',
  NAME          => 'Acme::Shell',
  PREREQ_PM     => $prereqs,
  LICENSE       => 'open_source',
  AUTHOR        => 'Alex Ayars <pause@nodekit.org>',
);
