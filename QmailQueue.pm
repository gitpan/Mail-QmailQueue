package Mail::QmailQueue;
# $Id: QmailQueue.pm,v 1.2 2001/10/07 09:55:48 ikechin Exp $
use strict;
use vars qw($VERSION);
use IO::Pipe;
use IO::Handle;

$VERSION = '0.01';

sub new {
  my $class = shift;
  my $bin = shift || "/var/qmail/bin/qmail-queue";
  my $self = {
	      _bin => $bin,
	      };
  bless $self,$class;
}

sub mail {
  my $self = shift;
  if ($_[0]) {
    $self->{mail} = shift;
  }
}

sub rcpt {
  my $self = shift;
  if (@_) {
    if ($self->{rcpt}) {
      push(@{$self->{rcpt}},@_);
    }
    else{
      $self->{rcpt} = [ @_ ];
    }
  }
}

sub to {
  my $self = shift;
  $self->rcpt(@_);
}

sub datasend {
  my $self = shift;
  $self->{data} = shift;
  $self->{data} =~ s/\r\n/\n/g;
  $self->{data} .= "\n";
  $self->_send;
}

sub _send {
  my $self = shift;
  my $data = IO::Pipe->new;
  my $addr = IO::Pipe->new;

  if(my $pid = fork){
    $data->writer;
    $addr->writer;
    $data->print($self->{data});
    $data->close;
    $addr->print("F" . $self->{mail} . "\0");
    foreach my $rcpt (@{$self->{rcpt}}) {
      $addr->print("T" . $rcpt . "\0");
    }
    $addr->print("\0");
    $addr->close;
    wait;
  } elsif (defined $pid) {
    my $fd0 = IO::Handle->new->fdopen(0,"w");
    my $fd1 = IO::Handle->new->fdopen(1,"w");
    $data->reader();
    $addr->reader();
    $fd0->fdopen(fileno($data),"r");
    $fd1->fdopen(fileno($addr),"r");
    exec($self->{_bin}) || die $!;
    exit;
  }
  else {
    die "Cannot fork!!";
  }
}

sub data {1;};
sub dataend {1;}
sub quit {1;}

1;
__END__

=head1 NAME

Mail::QmailQueue - Perl extension to using qmail-queue directry

=head1 SYNOPSIS

  use Mail::QmailQueue;
  
  

=head1 DESCRIPTION

Stub documentation for Mail::QmailQueue, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

=head1 SEE ALSO

L<Net::SMTP>.

=cut
