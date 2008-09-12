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

isa_ok($hive, 'Data::Hive');

$hive->foo->SET(1);

is(0 + $hive->bar,            0, "0 == ->bar");
{
  no warnings;
  is(0 + $hive->bar->GET,     0, "0 == ->bar->GET");
}
is(0 + $hive->bar->GETNUM,    0, "0 == ->bar->GETNUM");
is(0 + $hive->bar->GET(1),    1, "1 == ->bar->GET(1)");
is(0 + $hive->bar->GETNUM(1), 1, "1 == ->bar->GETNUM(1)");

is_deeply($store, { foo => 1 }, 'did not autovivify');
