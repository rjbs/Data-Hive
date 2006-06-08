#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use ok 'Data::Hive';
use ok 'Data::Hive::Store::Hash';

my $hive = Data::Hive->NEW({
  store => Data::Hive::Store::Hash->new(
    my $store = {}
  ),
});

my $tmp;

isa_ok($hive, 'Data::Hive');

$hive->foo->SET(1);

is_deeply($store, { foo => 1 }, 'changes made to store');

$tmp = 0 + $hive->bar;

is_deeply($store, { foo => 1 }, 'did not autovivify');

$hive->baz->quux->SET(2);

is_deeply($store, {
  foo => 1,
  baz => { quux => 2 }
}, 'deep set');

eval { $tmp = 0 + $hive->foo->bar };
like $@, qr/can't get key 'bar'/, "error on wrongly nested get";

eval { $hive->foo->bar->SET(3) };
like $@, qr/overwrite existing non-ref/, "error on wrongly nested set";

ok ! $hive->not->EXISTS, "non-existent key doesn't EXISTS";
ok   $hive->foo->EXISTS, "existing key does EXISTS";
