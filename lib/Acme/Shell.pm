#
# File: Acme/Shell.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package Acme::Shell;

our $VERSION = 0.002;

use strict;
use warnings;

use Error qw| :try |;

use File::HomeDir;
use Lexical::Persistence;
use Term::ReadLine;

use constant HistoryFilename => ".acmesh_history";

sub new {
  my $class = shift;
  my $self = shift || { };

  $self->{_perl}   ||= Lexical::Persistence->new();
  $self->{_buffer} ||= [ ];

  return bless $self, $class;
}

sub help {
  my $self = shift;

  print "Commands:\n";
  print "  exit          # exit\n";
  print "  ?pkgname      # perldoc for named package\n";
  print "  !cmd          # spawn system shell and run cmd\n";
  print "\n";
  print "Hitting <return> 2 times will eval the buffer and continue.\n";
  print "\n";
}

sub historyFile {
  my $self = shift;

  my $home = File::HomeDir->my_home;

  return join("/", $home, HistoryFilename);
}

sub run {
  my $self = shift;

  my $hasGNU;

  #
  # Taste the flavor of ReadLine
  #
  eval {
    require Term::ReadLine::Gnu;

    $hasGNU++;
  };

  my $class = ref($self);

  print "Welcome to $class.\n";
  print "\n";

  $self->help();

  my $perl = $self->{_perl};
  my $buffer = $self->{_buffer};

  my $prompt = "perl> ";

  my $term = Term::ReadLine->new($0);

  #
  # Set up history file
  #
  my $historyFile = $self->historyFile();

  if ( !$hasGNU ) {
    print STDERR "Term::ReadLine::Gnu not found. Some things won't work.\n";
  } elsif ( -e $historyFile && $term->can("addhistory") ) {
    open(HIST,'<', $historyFile);
    while(my $row = <HIST>){
      chomp $row;

      $term->addhistory($row);
    }
    close(HIST);
  }

  my $attribs = $term->Attribs();

  #
  # Set up tab completion
  #
  $attribs->{completion_entry_function} =
    $attribs->{list_completion_function};

  #
  # XXX TODO Get a better list of autocomplete words?
  #
  $attribs->{completion_word} = [
    "my", "use", "require", "if", "else", "sub", "constant", 
  ];

  #
  # Main event loop
  #
  while(1) {
    while( my $line = $term->readline($prompt) ) {
      if ( $line =~ /^\?(\w+.*)/ ) {
        print "Loading $1 documentation, please wait...\n";

        system("perldoc $1");

      } elsif ( $line =~ /^\!(\w+.*)/ ) {
        system($1);

      } elsif ( $line =~ /^(\?|help|h)$/i ) {
        $self->help();

      } elsif ( $line =~ /^exit$/i ) {
        exit();

      } else {
        push @{ $buffer }, $line;
      }
    }

    next if !@{ $buffer };

    try {
      $perl->do( join("\n", @{ $buffer }) );
    } catch Error with {
      my $error = shift;

      print "Compile failed! $error\n";
    };

    if ( $hasGNU ) {
      if ( -e $historyFile ) {
        $term->append_history(scalar(@{ $buffer }), $historyFile);
      } else {
        $term->WriteHistory($historyFile);
      }
    }

    #
    # Clear the buffer
    #
    while( @{ $buffer } ) {
      shift @{ $buffer };
    }
  }
}

1;
__END__
=pod

=head1 NAME

Acme::Shell - Interactive Perl 5 shell

=head1 VERSION

This document is for version B<.002> of Acme::Shell.

=head1 SYNOPSIS

A wrapper script, C<acme-sh>, is included with this distribution.

  Welcome to Acme::Shell.

  Commands:
    exit          # exit
    ?pkgname      # perldoc for named package
    !cmd          # spawn system shell and run cmd

  Hitting <return> 2 times will eval the buffer and continue.

  perl> print "$$\n";
  perl> 
  2730
  perl> my $var = "Hello there";
  perl> 
  perl> print "$var\n";
  perl> 
  Hello there
  perl> if ( $var ) {
  perl>   print "Still in scope: $var\n";
  perl> } else {
  perl>   die "This should never happen!\n";
  perl> }
  perl> 
  Still in scope: Hello there
  perl> exit

C<acme-sh> just does this:

  use Acme::Shell;

  my $shell = Acme::Shell->new();

  $shell->run();

=head1 DESCRIPTION

This module glues Term::ReadLine to Lexical::Persistence, forming
the basis for a very simple interactive Perl 5 shell. There isn't
much to it.

If Term::ReadLine::Gnu is not available on the local system, certain
features like tab completion, up/down arrow support, and history
file (C<~/.acmesh_history>) will not work.

=head1 SEE ALSO

L<Lexical::Persistence>, L<Term::ReadLine>

Acme::Shell is on GitHub: http://github.com/aayars/acme-sh

Acme::Shell was originally included as an experimental add-on for L<OP>.

=head1 AUTHOR

  Alex Ayars <pause@nodekit.org>

=head1 COPYRIGHT

  File: Acme/Shell.pm
 
  Copyright (c) 2009 TiVo Inc.
 
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Common Public License v1.0
  which accompanies this distribution, and is available at
  http://opensource.org/licenses/cpl1.0.txt

=cut
