package Oogly;
BEGIN {
  $Oogly::VERSION = '0.07';
}
# ABSTRACT: A Data validation idea that just might be ideal!

use strict;
use warnings;
use 5.008001;
use Data::Dumper;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 0;

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT @EXPORT_OK );
    @ISA    = qw( Exporter );
    @EXPORT = qw(
        new
        field
        mixin
        error
        errors
        check_field
        check_mixin
        validate
        use_mixin
        use_mixin_field
        basic_validate
        Oogly
    );
}


our $PACKAGE = (caller)[0];
our $FIELDS  = $PACKAGE::fields = {};
our $MIXINS  = $PACKAGE::mixins = {};


sub new {
    my $class = shift;
    my $params = shift;
    my $self  = {};
    bless $self, $class;
    my $flds = $FIELDS;
    my $mixs = $MIXINS;
    my %original_fields = %$flds;
    my %original_mixins = %$mixs;
    $self->{params} = $params;
    $self->{fields} = $flds;
    $self->{mixins} = $mixs;
    $self->{errors} = [];
    
    die "No valid parameters were found, parameters are required for validation"
        unless $self->{params} && ref($self->{params}) eq "HASH";
    
    # validate mixin directives
    foreach (keys %{$self->{mixins}}) {
        $self->check_mixin($_, $self->{mixins}->{$_});
    }
    # validate field directives
    foreach (keys %{$self->{fields}}) {
        unless ($_ eq 'errors') {
            $self->check_field($_, $self->{fields}->{$_});
            # check for and process mixin directives
            $self->use_mixin($_, $self->{fields}->{$_}->{mixin})
                if $self->{fields}->{$_}->{mixin};
        }
    }
    # check for and process a mixin_field directive
    foreach (keys %{$self->{fields}}) {
        unless ($_ eq 'errors') {
            $self->use_mixin_field($self->{fields}->{$_}->{mixin_field}, $_)
                if $self->{fields}->{$_}->{mixin_field}
                && $self->{fields}->{$self->{fields}->{$_}->{mixin_field}};
        }
    }
    return $self;
}


sub field {
    my %spec = @_;
    if (%spec) {
        my $flds = $FIELDS;
        while (my ($key, $val) = each (%spec)) {
            $val->{errors} = [];
            $val->{validation} = sub {0}
                unless $val->{validation};
            # overwrite bad, append good
            #$flds->{$key} = $val;
            if (ref($val) eq "HASH") {
                while (my ($k, $v) = each (%{$val})) {
                    $flds->{$key}->{$k} = $v;
                }
            }
        }
    }
    return 'field', %spec;
}


sub mixin {
    my %spec = @_;
    if (%spec) {
        my $mixs = $MIXINS;
        while (my ($key, $val) = each (%spec)) {
            $mixs->{$key} = $val;
        }
    }
    return 'mixin', %spec;
}


sub error {
    my ($self, @params) = @_;
    if (@params == 2) {
        # set error message
        my ($field, $error_msg) = @params;
        if (ref($field) eq "HASH" && (!ref($error_msg) && $error_msg)) {
            if (defined $self->{fields}->{$field->{name}}->{error}) {
                
                # temporary, may break stuff
                $error_msg = $self->{fields}->{$field->{name}}->{error};
                
                push @{$self->{fields}->{$field->{name}}->{errors}}, $error_msg unless
                    grep { $_ eq $error_msg } @{$self->{fields}->{$field->{name}}->{errors}};
                push @{$self->{errors}}, $error_msg unless
                    grep { $_ eq $error_msg } @{$self->{errors}};
            }
            else {
                push @{$self->{fields}->{$field->{name}}->{errors}}, $error_msg
                    unless grep { $_ eq $error_msg } @{$self->{fields}->{$field->{name}}->{errors}};
                push @{$self->{errors}}, $error_msg
                    unless grep { $_ eq $error_msg } @{$self->{errors}};
            }
        }
        else {
            die "Can't set error without proper field and error message data, " .
            "field must be a hashref with atleast name and value keys";
        }
    }
    elsif (@params == 1) {
        # return param-specific errors
        return $self->{fields}->{$params[0]}->{errors};
    }
    else {
        # return all errors
        return $self->{errors};
    }
}


sub errors {
    shift->error(@_);
}


sub check_mixin {
    my ($self, $mixin, $spec) = @_;
    my $directives = {
        required   => sub {1},
        min_length => sub {1},
        max_length => sub {1},
        data_type => sub {1},
        ref_type => sub {1},
        regex => sub {1},
        
    };
    
    foreach (keys %{$spec}) {
        if (!defined $directives->{$_}) {
            die "The `$_` directive supplied by the `$mixin` mixin is not supported";
        }
        if (!$directives->{$_}->()) {
            die "The `$_` directive supplied by the `$mixin` mixin is invalid";
        }
    }
}


sub check_field {
    my ($self, $field, $spec) = @_;
    my $directives = {
        mixin => sub {1},
        mixin_field => sub {1},
        validation => sub {1},
        errors => sub {1},
        label => sub {1},
        error => sub {1},
        value => sub {1},
        name => sub {1},
        
        required   => sub {1},
        min_length => sub {1},
        max_length => sub {1},
        data_type => sub {1},
        ref_type => sub {1},
        regex => sub {1},
    };
    foreach (keys %{$spec}) {
        if (!defined $directives->{$_}) {
            die "The `$_` directive supplied by the `$field` field is not supported";
        }
        if (!$directives->{$_}->()) {
            die "The `$_` directive supplied by the `$field` field is invalid";
        }
    }
}


sub use_mixin {
    my ($self, $field, $mixin_s ) = @_;
    if (ref($mixin_s) eq "ARRAY") {
        foreach my $mixin (@{$mixin_s}) {
            while (my($key, $val) = each (%{$self->{mixins}->{$mixin}})) {
                $self->{fields}->{$field}->{$key} = $val
                    unless defined $self->{fields}->{$field}->{$key};
            }
        }
    }
    else {
        while (my($key, $val) = each (%{$self->{mixins}->{$mixin_s}})) {
            $self->{fields}->{$field}->{$key} = $val
                unless defined $self->{fields}->{$field}->{$key};
        }
    }
}


sub use_mixin_field {
    my ($self, $field, $target) = @_;
    $self->check_field($field, $self->{fields}->{$field});
    while (my($key, $val) = each (%{$self->{fields}->{$field}})) {
        $self->{fields}->{$target}->{$key} = $val
            unless defined $self->{fields}->{$target}->{$key};
        if ($key eq 'mixin') {
            $self->use_mixin($target, $key);
        }
    }
}


sub validate {
    my ($self, @fields) = @_;
    if ($self->{params}) {
        if (!@fields) {
            # process all params
            foreach my $field (keys %{$self->{params}}) {
                if (!defined $self->{fields}->{$field}) {
                    die "Data validation field `$field` does not exist";
                }
                my $this = $self->{fields}->{$field};
                $this->{name} = $field;
                $this->{value} = $self->{params}->{$field};
                my @passed = (
                    $self,
                    $this,
                    $self->{params}
                );
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation
                $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
        else {
            foreach my $field (@fields) {
                if (!defined $self->{fields}->{$field}) {
                    die "Data validation field `$field` does not exist";
                }
                my $this = $self->{fields}->{$field};
                $this->{name} = $field;
                $this->{value} = $self->{params}->{$field};
                my @passed = (
                    $self,
                    $this,
                    $self->{params}
                );
                # execute simple validation
                $self->basic_validate($field, $this);
                # custom validation
                $self->{fields}->{$field}->{validation}->(@passed);
            }
        }
        return $self->{errors} ? 0 : 1;
    }
    else {
        return 0;
    }
}


sub basic_validate {
    my ($self, $field, $this) = @_;
    
    # does field have a label, if not use field name
    my $name  = $this->{label} ? $this->{label} : "parameter `$field`";
    my $value = $this->{value};
    
    # check if required
    if ($this->{required} && (! defined $value || $value eq '')) {
        my $error = defined $this->{error} ? $this->{error} : "$name is required";
        $self->error($this, $error);
    }
    
    if ($this->{required} || $value) {
    
        # check min character length
        if (defined $this->{min_length}) {
            if ($this->{min_length}) {
                if (length($value) < $this->{min_length}){
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name must contain at least " .
                        $this->{min_length} .
                        (int($this->{min_length}) > 1 ?
                         " characters" : " character");
                    $self->error($this, $error);
                }
            }
        }
        
        # check max character length
        if (defined $this->{max_length}) {
            if ($this->{max_length}) {
                if (length($value) > $this->{max_length}){
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name cannot be greater than " .
                        $this->{max_length} .
                        (int($this->{max_length}) > 1 ?
                         " characters" : " character");
                    $self->error($this, $error);
                }
            }
        }
        
        # check reference type
        if (defined $this->{ref_type}) {
            if ($this->{ref_type}) {
                unless (lc(ref($value)) eq lc($this->{ref_type})) {
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name is not being stored as " .
                        ($this->{ref_type} =~ /^[Aa]/ ? "an " : "a ") . 
                            $this->{ref_type} . " reference";
                    $self->error($this, $error);
                }
            }
        }
        
        # check data type
        if (defined $this->{data_type}) {
            if ($this->{data_type}) {
                
            }
        }
        
        # check against regex
        if (defined $this->{regex}) {
            if ($this->{regex}) {
                unless ($value =~ $this->{regex}) {
                    my $error = defined $this->{error} ? $this->{error} :
                    "$name failed regular expression testing " .
                        "using `$value`";
                    $self->error($this, $error);
                }
            }
        }
    }
}


sub Oogly {
    my %properties = @_;
    my $KEY  = undef;
       $KEY .= (@{['A'..'Z',0..9]}[rand(36)]) for (1..5);
    $PACKAGE = "Oogly::Instance::" . $KEY;
    
    my $code = "package $PACKAGE; use Oogly; our \$PACKAGE = '$PACKAGE'; ";
    $code .= "our \$FIELDS  = \$PACKAGE::fields = {}; ";
    $code .= "our \$MIXINS  = \$PACKAGE::mixins = {}; ";
    
    while (my($key, $value) = each(%properties)) {
        die "$key is not a supported property"
            unless $key eq 'mixins' || $key eq 'fields';
        if ($key eq 'mixins') {
            while (my($key, $value) = each(%{$properties{mixins}})) {
                $code .= "mixin('" . $key . "'," . Dumper($value) . ");";
            }
        }
        if ($key eq 'fields') {
            while (my($key, $value) = each(%{$properties{fields}})) {
                $code .= "field('" . $key . "'," . Dumper($value) . ");";
            }
        }
    } $code .= "1;";
    
    eval $code or die $@;
    return $PACKAGE;
}

1; # End of Oogly

__END__
=pod

=head1 NAME

Oogly - A Data validation idea that just might be ideal!

=head1 VERSION

version 0.07

=head1 SYNOPSIS

Oogly is a different approach to data validation, it attempts to simplify and
centralize data validation rules to ensure DRY (don't repeat yourself) code.
PLEASE NOTE! It is not the intent of this module to provide validation routines 
but instead to provide simplistic validation flow-control, and promote code
reuse. The following is an example of that...

    use MyApp::Validation;
    my $app = MyApp::Validation->new(\%params);
    if ($app->validate('login', 'password')){
        ...
    }

    package MyApp::Validation
    use Oogly;

    # define a mixin, a sortof template that can be included with other rules
    # by using the mixin directive
    mixin 'default' => {
        required    => 1,
        min_length  => 4,
        max_length  => 255
    };
    
    # define a data validation rule for parameter `login` using the default
    # mixin where the `login` must be between 4-255 characters long and have
    # at least one letter and number
    field 'login' => {
        label => 'user login',
        mixin => 'default',
        validation => sub {
            my ($self, $this, $params) = @_;
            my ($name, $value) = ($this->{name}, $this->{value});
            $self->error($this, "field $name must contain at least one letter and number")
                if ($value !~ /[a-zA-Z]/ && $value !~ /[0-9]/);
        }
    };
    
    # define a data validation rule for parameter `password` using the
    # previously defined field `login` as the mixin (template)
    field 'password' => {
        mixin_field => 'login',
        label => 'user password'
    };

And now for my second and final act, using Oogly outside of a package.

    #!/usr/bin/perl
    my $i = Oogly(
            mixins => {
                default => {
                    required    => 1,
                    min_length  => 4,
                    max_length  => 255
                }
            },
            fields => {
                login => {
                    label => 'user login',
                    mixin => 'default',
                    validation => sub {
                        my ($self, $this, $params) = @_;
                        my ($name, $value) = ($this->{name}, $this->{value});
                        $self->error($this, "field $name must contain at least one letter and number")
                            if ($value !~ /[a-zA-Z]/ && $value !~ /[0-9]/);
                    }
                },
                password => {
                    mixin_field => 'login',
                    label => 'user password'
                }
            },
    );
    
    # Important store the new instance $i->new
    $o = $i->new({ login => 'root', password => '...' });
    
    if ($o->validate) {
        ...
    }

=head1 METHODS

=head2 new

The new method instantiates a new Oogly or Oogly package instance.

=head2 field

The field function defines the validation rules for the specified parameter it
is named after. e.g. field 'some_data' => {...}, validates against the value of 
the hash reference where the key is `some_data`.

    field 'some_param' => {
        mixin => 'default',
        validation => sub {
            my ($v, $this, $params) = @_;
            $v->error($this, "...")
                if ...
        }
    };

    Fields are comprised of specific directives, those directives are as follows:
    name: The name of the field (auto set)
    value: The value of the parameter matching the name of the field (auto set)
    mixin: The template to be used to copy directives from
    
    mixin 'template' => {
        required => 1
    };
    
    field 'a_field' => {
        mixin => 'template'
    }
    
    mixin_field: The field to be used as a mixin(template) to copy directives from
    
    field 'a_field' => {
        required => 1,
        min_length => 2,
        max_length => 10
    };
    
    field 'b_field' => {
        mixin_field => 'a_field'
    };
    
    validation: A validation routine that returns true or false
    
    field '...' => {
        validation => sub {
            my ($self, $field, $all_parameters) = @_;
            return 1
        }
    };
    
    errors: The collection of errors encountered during processing (auto set arrayref)
    label: An alias for the field name, something more human-readable
    error: A custom error message, displayed instead of the generic ones
    required : Determines whether the field is required or not, takes 1/0 true of false
    min_length: Determines the maximum length of characters allowed
    max_length: Determines the minimum length of characters allowed
    ref_type: Determines whether the field value is a valid perl reference variable
    regex: Determines whether the field value passed the regular expression test
    
    field 'c_field' => {
        label => 'a field labeled c',
        error => 'a field labeled c cannot ',
        required => 1,
        min_length => 2,
        max_length => 25,
        ref_type => 'array',
        regex => '^\d+$'
    };

=head2 mixin

The mixin function defines validation rule templates to be later reused by
more specifically defined fields.

    mixin 'default' => {
        required    => 1,
        min_length  => 4,
        max_length  => 255
    };

=head2 error

The error function is used to set and/or retrieve errors encountered or set
during validation. The error function with no parameters returns the error
message arrayref which can be used to output a single concatenated error message
a with delimeter.

    $self->error() # returns an array of errors
    join '<br/>', $self->error(); # html-break delimeted errors
    $self->error('some_param'); # show parameter-specific error messages arrayref
    $self->error($this, "$name must conform ..."); # set error, see `field` function

=head2 errors

The errors function is a synonym for the error function.

=head2 check_mixin

The check_mixin function is used internally to validate the defined keys and
values of mixins.

=head2 check_field

The check_field function is used internally to validate the defined keys and
values of fields.

=head2 use_mixin

The use_mixin function sequentially applies defined mixin parameteres
(as templates)to the specified field.

=head2 use_mixin_field

The use_mixin_field function copies the properties (directives) of a specified
field to the target field processing copied mixins along the way.

=head2 validate

The validate function sequentially checks the passed-in field names against their
defined validation rules and returns 0 or 1.

=head2 basic_validate

The basic_validate function processes the pre-defined contraints e.g.,
required, min_length, max_length, etc.

=head2 Oogly

The Oogly method encapsulates fields and mixins and returns an Oogly instance
for further validation. This method exist for situations where Oogly is use
outside of a specific validation package.

    my $i = Oogly(
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
    
    # Important store the new instance
    $o = $i->new({ test1 => '...' });
    
    if ($o->validate('test1')) {
        ...
    }

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

