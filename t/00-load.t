#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Oogly' );
}

diag( "Testing Oogly $Oogly::VERSION, Perl $], $^X" );
