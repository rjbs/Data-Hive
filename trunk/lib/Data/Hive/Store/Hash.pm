package Data::Hive::Store::Hash;

use strict;
use warnings;

=head1 NAME

Data::Hive::Store::Hash

=head1 DESCRIPTION

Simple hash store for Data::Hive.

=head1 METHODS

=head2 new

  my $store = Data::Hive::Store::Hash->new(\%hash);

Takes a hashref to use as the store.

=cut

sub new {
  my ($class, $hash) = @_;
  return bless \$hash => $class;
}

=head2 get

Use given C<< \@path >> as nesting keys in the hashref
store.

=cut

sub _die {
  require Carp::Clan;
  Carp::Clan->import('^Data::Hive($|::)');
  croak(shift);
}

sub get {
  my ($self, $path) = @_;
  my $hash = $$self;
  while (@$path) {
    my $seg = shift @$path;
    if (defined $hash and not ref $hash) {
      _die("can't get key '$seg' of non-ref value '$hash'");
    }
    unless (exists $hash->{$seg}) {
      return;
    }
    $hash = $hash->{$seg};
  }
  return $hash;
}

=head2 set

See L</get>.  Dies if you try to set a key underneath an
existing non-hashref key, e.g.:

  $hash = { foo => 1 };
  $store->set([ 'foo', 'bar' ], 2); # dies

=cut

sub set {
  my ($self, $path, $key) = @_;
  my $hash = $$self;
  while (@$path > 1) {
    my $seg = shift @$path;
    if (exists $hash->{$seg} and not ref $hash->{$seg}) {
      _die("can't overwrite existing non-ref value: '$hash->{$seg}'");
    }
    $hash = $hash->{$seg} ||= {};
  }
  $hash->{$path->[0]} = $key;
}

=head2 name

Returns a string, potentially suitable for eval-ing,
describing a hash dereference of a variable called C<<
$STORE >>.

  "$STORE->{foo}->{bar}"

This is probably not very useful.

=cut

sub name {
  my ($self, $path) = @_;
  return join '->', '$STORE', map { "{'$_'}" } @$path;
}

1;
