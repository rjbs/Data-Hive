#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use ok 'Data::Hive';

my $hive = Data::Hive->NEW({
  store => Data::Hive::Store::Hash->new(
    my $store = {}
  ),
});

my $tmp;

isa_ok($hive, 'Data::Hive');

$hive->foo->SET(1);

is_deeply($store, { foo => 1 }, 'changes made to store');

$tmp = $hive->bar;

is_deeply($store, { foo => 1 }, 'did not autovivify');

$hive->baz->quux->SET(2);

is_deeply($store, {
  foo => 1,
  baz => { quux => 2 }
}, 'deep set');


