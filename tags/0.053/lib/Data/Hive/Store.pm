package Data::Hive::Store;

use strict;
use warnings;

=head1 NAME

Data::Hive::Store

=head1 DESCRIPTION

Data::Hive::Store is a generic interface to a backend store
for Data::Hive.

=head1 METHODS

All methods are passed at least a 'path' (arrayref of
namespace pieces).  Joining the path in a way that is
meaningful is most of the point of the Store modules.

=head2 get

  print $store->get(\@path, \%opt);

Return the resource represented by the given path, however
C<< $store >> is structured.  This could map to e.g.

  $hash->{foo}->{bar}

  $obj->get('foo.bar')

  io('/foo/bar')->all

depending on the Store module involved.

=head2 set

  $store->set(\@path, $value, \%opt);

Analogous to C<< get >>.

=head2 name

  print $store->name(\@path, \%opt);

Return a store-specific name for the given path.  This is
primarily useful for stores that may be accessed
independently of the hive; in the C<< io >> example above,
some external process/function may want to write to C<<
/foo/bar >> directly.

=head2 exists

  if ($store->exists(\@path, \%opt)) { ... }

Returns true if the given path exists in the store.

=head2 delete

  $store->delete(\@path, \%opt);

Delete the given path from the store.  Return the previous value, if any.

=cut

BEGIN {
  for my $meth (qw(get set name exists delete)) {
    no strict 'refs';
    *$meth = sub { require Carp; Carp::croak("$_[0] does not implement $meth") };
  }
}

1;
