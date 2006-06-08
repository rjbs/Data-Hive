#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::MockObject;

use ok 'Data::Hive';
use ok 'Data::Hive::Store::Param';

my $obj = Test::MockObject->new;
my $param = {};
$obj->mock(
  info => sub {
    my (undef, $key, $val) = @_;
    $param->{$key} = $val if @_ > 2;
    return $param->{$key};
  },
);
$obj->mock(
  info_exists => sub {
    my (undef, $key) = @_;
    return exists $param->{$key};
  }
);

my $hive = Data::Hive->NEW({
  store_class => 'Param',
  store_args  => [ $obj, {
    method => 'info',
    separator => '/',
    exists => 'info_exists',
  } ],
});

%$param = (
  foo => 1,
  'bar/baz' => 2,
);

is $hive->bar->baz, 2, 'GET';
$hive->foo->SET(3);
is_deeply $param, { foo => 3, 'bar/baz' => 2 }, 'SET';

is $hive->bar->baz->NAME, 'bar/baz', 'NAME';

ok ! $hive->not->EXISTS, "non-existent key doesn't EXISTS";
ok   $hive->foo->EXISTS, "existing key does EXISTS";
