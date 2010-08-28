#!perl
use strict;
use warnings;

use Test::More;
use Data::Hive;
use Data::Hive::Store::Hash;

{
  my $hive = Data::Hive->NEW({ store => Data::Hive::Store::Hash->new });

  isa_ok($hive, 'Data::Hive');

  subtest 'value of zero' => sub {
    $hive->zero->SET(0);

    is($hive->zero->GET,    0, "/zero is 0");
    is($hive->zero->GETSTR, 0, "/zero is 0");
    is($hive->zero->GETNUM, 0, "/zero is 0");
  };

  subtest 'value of one' => sub {
    $hive->one->SET(1);

    is($hive->one->GET,    1, "/one is 1");
    is($hive->one->GETSTR, 1, "... via GETSTR is 1");
    is($hive->one->GETNUM, 1, "... via GETNUM is 1");
  };

  subtest 'value of empty string' => sub {
    $hive->empty->SET('');

    is($hive->empty->GET,    '', "/empty is 1");
    is($hive->empty->GETSTR, '', "... via GETSTR is ''");
    is($hive->empty->GETNUM,  0, "... via GETNUM is 0");
  };

  subtest 'undef, existing value' => sub {
    $hive->undef->SET(undef);

    is($hive->undef->GET,    undef, "/undef is undef");
    is($hive->undef->GETSTR, '',    "... via GETSTR is ''");
    is($hive->undef->GETNUM, 0,     "... via GETNUM is 0");

    {
      no warnings 'uninitialized';
      is( 0 + $hive->undef,  0, q{...  0 + $hive->undef == 0});
      is('' . $hive->undef, '', q{... '' . $hive->undef eq ''});
    }
  };

  subtest 'non-existing value' => sub {
    is($hive->missing->GET,    undef, "/missing is undef");
    is($hive->missing->GETSTR, '',    "... via GETSTR is ''");
    is($hive->missing->GETNUM, 0,     "... via GETNUM is 0");

    {
      no warnings 'uninitialized';
      is( 0 + $hive->missing,  0, q{...  0 + $hive->missing == 0});
      is('' . $hive->missing, '', q{... '' . $hive->missing eq ''});
    }
  };

  is($hive->missing->GET(1),    1, " == ->missing->GET(1)");
  is($hive->missing->GET(0),    0, "0 == ->missing->GET(0)");
  is($hive->missing->GET(''),  '', "'' == ->missing->GET('')");

  is($hive->missing->GETNUM,    0, "0 == ->missing->GETNUM");
  is($hive->missing->GETNUM(1), 1, "1 == ->missing->GETNUM(1)");

  is($hive->missing->GETNUM(1), 1, "1 == ->missing->GETNUM(1)");


  is_deeply(
    [ sort $hive->KEYS  ],
    [ qw(empty one undef zero) ],
    "we have the right top-level keys",
  );

  is_deeply(
    $hive->STORE->hash_store,
    {
      one   => { '' => 1 },
      empty => { '' => '' },
      undef => { '' => undef },
      zero  => { '' => 0 },
    },
    'did not autovivify'
  );
}

for my $class (qw(
  Hash
  +Data::Hive::Store::Hash
  =Data::Hive::Store::Hash
)) {
  my $hive = Data::Hive->NEW({ store_class => $class });

  isa_ok($hive->STORE, 'Data::Hive::Store::Hash', "store from $class");
}

done_testing;
