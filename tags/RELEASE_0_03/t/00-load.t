#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Hive' );
}

diag( "Testing Data::Hive $Data::Hive::VERSION, Perl $], $^X" );
