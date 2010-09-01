use strict;
use warnings;
package Data::Hive::Test;
# ABSTRACT: a bundle of tests for Data::Hive stores

use Data::Hive;
use Data::Hive::Store::Hash;

use Test::More 0.94; # subtest

=head1 SYNOPSIS

  use Test::More;

  use Data::Hive::Test;
  use Data::Hive::Store::MyNewStore;

  Data::Hive::Test->test_new_hive({ store_class => 'MyNewStore' });

  # rest of your tests for your store

  done_testing;

=head1 DESCRIPTION

Data::Hive::Test is a library of tests that should be passable for any
conformant L<Data::Hive::Store> implementation.  It provides a method for
running a suite of tests -- which may expand or change -- that check the
behavior of a hive store by building a hive around it and testing its behavior.

=method test_new_hive

  Data::Hive::Test->test_new_hive( $desc, \%args_to_NEW );

This method expects an (optional) description followed by a hashref of
arguments to be passed to Data::Hive's C<L<NEW|Data::Hive/NEW>> method.  A new
hive will be constructed with those arguments and a single subtest will be run,
including subtests that should pass against any conformant Data::Hive::Store
implementation.

If the tests pass, the method will return the hive.  If they fail, the method
will return false.

=method test_existing_hive

  Data::Hive::Test->test_existing_hive( $desc, $hive );

This method behaves just like C<test_new_hive>, but expects a hive rather than
arguments to use to build one.

=cut

sub test_new_hive {
  my ($self, $desc, $arg) = @_;

  if (@_ == 2) {
    $arg  = $desc;
    $desc = "hive tests from Data::Hive::Test";
  }

  my $hive = Data::Hive->NEW($arg);

  test_existing_hive($desc, $hive);
}

sub test_existing_hive {
  my ($self, $desc, $hive) = @_;

  if (@_ == 2) {
    $hive = $desc;
    $desc = "hive tests from Data::Hive::Test";
  }

  $desc = "Data::Hive::Test: $desc";

  my $passed = subtest $desc => sub {
    isa_ok($hive, 'Data::Hive');

    is_deeply(
      [ $hive->KEYS ],
      [ ],
      "we're starting with an empty hive",
    );

    subtest 'value of one' => sub {
      ok(! $hive->one->EXISTS, "before being set, ->one doesn't EXISTS");

      $hive->one->SET(1);

      ok($hive->one->EXISTS, "after being set, ->one EXISTS");

      is($hive->one->GET,      1, "->one->GET is 1");
      is($hive->one->GET(10),  1, "->one->GET(10) is 1");
    };

    subtest 'value of zero' => sub {
      ok(! $hive->zero->EXISTS, "before being set, ->zero doesn't EXISTS");

      $hive->zero->SET(0);

      ok($hive->zero->EXISTS, "after being set, ->zero EXISTS");

      is($hive->zero->GET,      0, "->zero->GET is 0");
      is($hive->zero->GET(10),  0, "->zero->GET(10) is 0");
    };

    subtest 'value of empty string' => sub {
      ok(! $hive->empty->EXISTS, "before being set, ->empty doesn't EXISTS");

      $hive->empty->SET('');

      ok($hive->empty->EXISTS, "after being set, ->empty EXISTS");

      is($hive->empty->GET,     '', "->empty->GET is ''");
      is($hive->empty->GET(10), '', "->empty->GET(10) is ''");
    };

    subtest 'undef, existing value' => sub {
      ok(! $hive->undef->EXISTS, "before being set, ->undef doesn't EXISTS");

      $hive->undef->SET(undef);

      ok($hive->undef->EXISTS, "after being set, ->undef EXISTS");

      is($hive->undef->GET,     undef, "->undef->GET is undef");
      is($hive->undef->GET(10),    10, "->undef->GET(10) is undef");
    };

    subtest 'non-existing value' => sub {
      ok(! $hive->missing->EXISTS, "before being set, ->missing doesn't EXISTS");

      is($hive->missing->GET,    undef, "->missing is undef");

      ok(! $hive->missing->EXISTS, "mere GET-ing won't cause ->missing to EXIST");

      is($hive->missing->GET(10),  10, "->missing->GET(10) is 10");
    };

    subtest 'nested value' => sub {
      ok(
        ! $hive->two->EXISTS,
        "before setting ->two->deep, ->two doesn't EXISTS"
      );

      ok(
        ! $hive->two->deep->EXISTS,
        "before setting ->two->deep, ->two->deep doesn't EXISTS"
      );

      is(
        $hive->two->deep->GET,
        undef,
        "before being set, ->two->deep is undef"
      );

      $hive->two->deep->SET('2D');

      ok(
        ! $hive->two->EXISTS,
        "after setting ->two->deep, ->two still doesn't EXISTS"
      );

      ok(
        $hive->two->deep->EXISTS,
        "after setting ->two->deep, ->two->deep EXISTS"
      );

      is(
        $hive->two->deep->GET,
        '2D',
        "after being set, ->two->deep->GET returns '2D'",
      );

      is(
        $hive->two->deep->GET(10),
        '2D',
        "after being set, ->two->deep->GET(10) returns '2D'",
      );
    };

    is_deeply(
      [ sort $hive->KEYS  ],
      [ qw(empty one two undef zero) ],
      "in the end, we have the right top-level keys",
    );

    is(
      $hive->two->deep->fake->whatever->ROOT->two->deep->GET,
      '2D',
      "we can get back to the root easily with ROOT",
    );

    subtest 'COPY_ONTO' => sub {
      $hive->copy->x->y->z->SET(1);
      $hive->copy->a->b->SET(2);
      $hive->copy->a->b->c->d->SET(3);

      my $target = Data::Hive->NEW({ store => Data::Hive::Store::Hash->new });

      $hive->copy->COPY_ONTO($target->clone);

      is_deeply(
        $target->STORE->hash_store,
        {
          'clone.x.y.z'   => '1',
          'clone.a.b'     => '2',
          'clone.a.b.c.d' => '3',
        },
        "we can copy structures",
      );
    };

    subtest 'DELETE_ALL' => sub {
      $hive->doomed->alpha->branch->value->SET(1);
      $hive->doomed->bravo->branch->value->SET(1);

      is_deeply(
        [ sort $hive->doomed->KEYS ],
        [ qw(alpha bravo) ],
        "created hive with two subhives",
      );

      $hive->doomed->alpha->DELETE_ALL;

      is_deeply(
        [ sort $hive->doomed->KEYS ],
        [ qw(bravo) ],
        "doing a DELETE_ALL gets rid of all deeper values",
      );

      is(
        $hive->doomed->alpha->branch->value->GET,
        undef,
        "the deeper value is now undef",
      );

      ok(
        ! $hive->doomed->alpha->branch->value->EXISTS,
        "the deeper value does not exist",
      );

      is(
        $hive->doomed->bravo->branch->value->GET,
        1,
        "the deep value on another branch is not gone",
      );
    };
  };

  return $passed ? $hive : ();
}

1;
