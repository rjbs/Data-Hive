#!perl

use strict;
use warnings;

use Test::More;

use Data::Hive;
use Data::Hive::Store::Param;

{
  package Infostore;
  sub new { bless {} => $_[0] }

  sub info {
    my ($self, $key, $val) = @_;
    return keys %$self if @_ == 1;
    $self->{$key} = $val if @_ > 2;
    return $self->{$key};
  }

  sub info_exists {
    my ($self, $key) = @_;
    return exists $self->{$key};
  }

  sub info_delete {
    my ($self, $key) = @_;
    return delete $self->{$key};
  }
}

my $infostore = Infostore->new;

my $hive = Data::Hive->NEW({
  store_class => 'Param',
  store_args  => [ $infostore, {
    method    => 'info',
    separator => '/',
    exists => 'info_exists',
    delete => 'info_delete',
  } ],
});

$infostore->info(foo       => 1);
$infostore->info('bar/baz' => 2);

is $hive->bar->baz, 2, 'GET';
$hive->foo->SET(3);
is_deeply $infostore, { foo => 3, 'bar/baz' => 2 }, 'SET';

is $hive->bar->baz->NAME, 'bar/baz', 'NAME';

ok ! $hive->not->EXISTS, "non-existent key doesn't EXISTS";
ok   $hive->foo->EXISTS, "existing key does EXISTS";

$hive->ITEM("and/or")->SET(17);

is_deeply $infostore, { foo => 3, 'bar/baz' => 2, 'and%2for' => 17 },
  'SET (with escape)';
is $hive->ITEM("and/or"), 17, 'GET (with escape)';

is $hive->bar->baz->DELETE, 2, "delete returns old value";
is_deeply $infostore, { foo => 3, 'and%2for' => 17 }, "delete removed item";

$hive->foo->bar->SET(4);
$hive->foo->bar->baz->SET(5);
$hive->foo->quux->baz->SET(6);

is_deeply(
  [ sort $hive->KEYS ],
  [ qw(and/or foo) ],
  "get the top level KEYS",
);

is_deeply(
  [ sort $hive->foo->KEYS ],
  [ qw(bar quux) ],
  "get the KEYS under foo",
);

is_deeply(
  [ sort $hive->foo->bar->KEYS ],
  [ qw(baz) ],
  "get the KEYS under foo/bar",
);

done_testing;
