#!perl -T
use Test::More tests => 2;

BEGIN {
	use_ok( 'Oogly', ':all' );
}

# use Oogly outside of a package
my $val = Oogly(
	mixins => {
		'default' => {
			required => 1
		}
	},
	fields => {
		'test1' => {
			mixin => 'default'
		}
	},
);

$val = $val->new({ test1 => 1 }); $val->validate();
ok(!@{$val->errors}, 'packageless validation test');

1;