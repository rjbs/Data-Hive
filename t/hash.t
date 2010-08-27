#!perl
use strict;
use warnings;

use Data::Hive;
use Data::Hive::Store::Hash;

use Test::More 0.88;

my $hive  = Data::Hive->NEW({
  store_class => 'Hash',
});

my $tmp;

isa_ok($hive,      'Data::Hive', 'top-level hive');

isa_ok($hive->foo, 'Data::Hive', '"foo" subhive');

$hive->foo->SET(1);

is_deeply(
  $hive->STORE->hash_store,
  { foo => { '' => 1 } },
  'changes made to store',
);

$hive->bar->baz->GET;

is_deeply(
  $hive->STORE->hash_store,
  { foo => { '' => 1 } },
  'did not autovivify'
);

$hive->baz->quux->SET(2);

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => { '' => 1 },
    baz => { quux => { '' => 2 } },
  },
  'deep set',
);

is(
  $hive->foo->GET,
  1,
  "get the 1 from ->foo",
);

is(
  $hive->foo->bar->GET,
  undef,
  "find nothing at ->foo->bar",
);

$hive->foo->bar->SET(3);

is(
  $hive->foo->bar->GET,
  3,
  "wrote and retrieved 3 from ->foo->bar",
);

ok ! $hive->not->EXISTS, "non-existent key doesn't EXISTS";
ok   $hive->foo->EXISTS, "existing key does EXISTS";

my $quux = $hive->baz->quux;
is $quux->GET, 2, "get from saved leaf";
is $quux->DELETE, 2, "delete returned old value";
is_deeply($hive->hash_store, {
  foo => 1,
  baz => { },
}, "deep delete");

done_testing;
