use strict;
use warnings;

use Test::More 0.88;

use Data::Hive;
use Data::Hive::Store::Hash;

use Try::Tiny;

sub exception (&) {
  my ($code) = @_;

  return try { $code->(); return } catch { return $_ };
}

isnt(
  exception { Data::Hive->NEW },
  undef,
  "we can't create a hive with no means to make a store",
);

isnt(
  exception { Data::Hive->NEW({}) },
  undef,
  "we can't create a hive with no means to make a store",
);

like(
  exception {
    my $store = Data::Hive::Store::Hash->new;
    Data::Hive->NEW({ store => $store, store_class => (ref $store) }) },
  undef,
  "we can't create a hive with no means to make a store",
);

done_testing;
