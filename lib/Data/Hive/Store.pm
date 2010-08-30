use strict;
use warnings;
package Data::Hive::Store;
# ABSTRACT: a backend storage driver for Data::Hive

use Carp ();

=head1 DESCRIPTION

Data::Hive::Store is a generic interface to a backend store
for Data::Hive.

=head1 METHODS

All methods are passed at least a 'path' (arrayref of namespace pieces).  Store
classes exist to operate on the entities found at named paths.

=head2 get

  print $store->get(\@path, \%opt);

Return the resource represented by the given path.

=head2 set

  $store->set(\@path, $value, \%opt);

Analogous to C<< get >>.

=head2 name

  print $store->name(\@path, \%opt);

Return a store-specific name for the given path.  This is primarily useful for
stores that may be accessed independently of the hive.

=head2 exists

  if ($store->exists(\@path, \%opt)) { ... }

Returns true if the given path exists in the store.

=head2 delete

  $store->delete(\@path, \%opt);

Delete the given path from the store.  Return the previous value, if any.

=head2 keys

  my @keys = $store->keys(\@path, \%opt);

This returns a list of next-level path elements that lead toward existing
values.  For more information on the expected behavior, see the L<KEYS
method|Data:Hive/keys> in Data::Hive.

=cut

BEGIN {
  for my $meth (qw(get set name exists delete keys)) {
    no strict 'refs';
    *$meth = sub { Carp::croak("$_[0] does not implement $meth") };
  }
}

1;
