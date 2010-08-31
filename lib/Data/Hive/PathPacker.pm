use strict;
use warnings;
package Data::Hive::PathPacker;
# ABSTRACT: a thing that converts paths to strings and then back

=head1 DESCRIPTION

Data::Hive::PathPacker classes are used by some L<Data::Hive::Store> classes to convert hive paths to strings so that deep hives can be stored in flat storage.

Path packers must implement two methods:

=method pack_path

  my $str = $packer->pack_path( \@path );

This method is passed an arrayref of path parts and returns a string to be used
as a key in flat storage for the path.

=method unpack_path

  my $path_arrayref = $packer->unpack_path( $str );

This method is passed a string and returns an arrayref of path parts
represented by the string.

=cut

1;
