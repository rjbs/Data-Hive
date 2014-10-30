use strict;
use warnings;
package Data::Hive::PathPacker::Strict;
# ABSTRACT: a simple, strict path packer

use parent 'Data::Hive::PathPacker';

use Carp ();

=head1 DESCRIPTION

The Strict path packer is the simplest useful implementation of
L<Data::Hive::PathPacker>.  It joins path parts together with a fixed string
and splits them apart on the same string.  If the fixed string occurs any path
part, an exception is thrown.

=method new

  my $packer = Data::Hive::PathPacker::Strict->new( \%arg );

The only valid argument is C<separator>, which is the string used to join path
parts.  It defaults to a single period.

=cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $guts = {
    separator => $arg->{separator} || '.',
  };

  return bless $guts => $class;
}

sub pack_path {
  my ($self, $path) = @_;

  my $sep     = $self->{separator};
  my @illegal = grep { /\Q$sep\E/ } @$path;

  Carp::confess("illegal hive path parts: @illegal") if @illegal;

  return join $sep, @$path;
}

sub unpack_path {
  my ($self, $str) = @_;

  my $sep = $self->{separator};
  return [ split /\Q$sep\E/, $str ];
}

1;
