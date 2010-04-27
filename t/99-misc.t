#!perl -T
package Test::Validation;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Oogly' );
}

mixin 'test' => {
    required => 15,
    min_length => 1,
    max_length => 1,
    regex => '^\d$'
};

field 'some_val' => {
    label => 'some value',
    mixin => 'test',
    validation => sub {
        my ($o, $this, $params) = @_;
        my ($name, $value) = ($this->{label}, $this->{value});
        $o->error($this, "$name failed miserably and should never be $value...");
    }
};


# fix: NOT overwriting hash data
field 'other_data' => {
    label => 'other data',
    mixin_field => 'some_val1',
};

my $tv = Test::Validation->new({ some_val => 'test' });
$tv->validate('some_val', 'other_data');
ok(@{$tv->errors} == 3, "miscellaneous tests");

1;