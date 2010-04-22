#!perl -T
package Test::Validation;
use Test::More tests => 3;

BEGIN {
	use_ok( 'Oogly' );
}

field 'some_val' => {
    required => 1,
};

# no params failure
eval { my $tv0 = Test::Validation->new(); };
ok($@, "no parameters failure");

# test required param
my $tv1 = Test::Validation->new({some_val => ''});
$tv1->validate('some_val');
ok((($tv1->errors('some_val'))[0]) eq 'parameter `some_val` is required',
   "required field test");

1;