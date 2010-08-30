use strict;
use warnings;
package Data::Hive::Store::Param;
# ABSTRACT: CGI::param-like store for Data::Hive

=head1 DESCRIPTION

This hive store will soon be overhauled.

Basically, it expects to access a hive in an object with CGI's C<param> method,
or the numerous other things with that interface.

=method new

  # use default method name 'param'
  my $store = Data::Hive::Store::Param->new($obj);

  # use different method name 'info'
  my $store = Data::Hive::Store::Param->new($obj, { method => 'info' });

  # escape certain characters in keys
  my $store = Data::Hive::Store::Param->new($obj, { escape => './!' });

Return a new Param store.

Several interesting arguments can be passed in a hashref after the first
(mandatory) object argument.

=begin :list 

= method

Use a different method name on the object (default is 'param').

This method should have the "usual" behavior for a C<param> method:

=for :list
* calling C<< $obj->param >> with no arguments returns all param names
* calling C<< $obj->param($name) >> returns the value for that name
* calling C<< $obj->param($name, $value) >> sets the value for the name

The Param store does not check the types of values, but for interoperation with
other stores, sticking to simple scalars is a good idea.

= escape and unescape

These coderefs are used to escape and path parts so that they can be split and
joined without ambiguity.  The callbacks will be called like this:

  my $result = do {
    local $_ = $path_part;
    $store->$callback( $path_part );
  }

The default escape routine uses URI-like encoding on non-word characters.

= join, split, and separator

The C<join> coderef is used to join pre-escaped path parts.  C<split> is used
to split up a complete name before unescaping the parts.

By default, they will use a simple perl join and split on the character given
in the C<separator> option.

= exists

This is a coderef used to check whether a given parameter name exists.  It will
be called as a method on the Data::Hive::Store::Param object with the path name
as its argument.

The default behavior gets a list of all parameters and checks whether the given
name appears in it.

= delete

This is a coderef used to delete the value for a path from the hive.  It will
be called as a method on the Data::Hive::Store::Param object with the path name
as its argument.

The default behavior is to call the C<delete> method on the object providing
the C<param> method.

=end :list

=cut

sub escaped_path {
  my ($self, $path) = @_;

  my $escape = $self->{escape};
  my $join   = $self->{join};

  return $self->$join([ map {; $self->$escape($_) } @$path ]);
}

sub name { $_[0]->escaped_path($_[1]) }

sub parsed_path {
  my ($self, $str) = @_;

  my $split    = $self->{split};
  my $unescape = $self->{unescape};

  return [ map {; $self->$unescape($_) } $self->$split($str) ];
}

sub new {
  my ($class, $obj, $arg) = @_;
  $arg ||= {};

  my $guts = {
    obj       => $obj,

    separator => $arg->{separator} || '.',

    escape    => $arg->{escape}   || sub  {
      my ($self, $str) = @_;
      $str =~ s/([^a-z0-9_])/sprintf("%%%x", ord($1))/gie;
      return $str;
    },

    unescape  => $arg->{unescape} || sub {
      my ($self, $str) = @_;
      $str =~ s/%([0-9a-f]{2})/chr(hex($1))/ge;
      return $str;
    },

    join      => $arg->{join}  || sub { join $_[0]{separator}, @{$_[1]} },
    split     => $arg->{split} || sub { split /\Q$_[0]{separator}/, $_[1] },

    method    => $arg->{method} || 'param',

    exists    => $arg->{exists} || sub {
      my ($self, $key) = @_;
      my $method = $self->{method};
      my $exists = grep { $key eq $_ } $self->param_store->$method;
      return ! ! $exists;
    },

    delete    => $arg->{delete} || sub {
      my ($self, $key) = @_;
      $self->param_store->delete($key);
    },
  };

  return bless $guts => $class;
}

sub param_store { $_[0]{obj} }

sub _param {
  my $self = shift;
  my $meth = $self->{method};
  my $path = $self->name(shift);
  return $self->param_store->$meth($path, @_);
}

sub get {
  my ($self, $path) = @_;
  return $self->_param($path);
}

sub set {
  my ($self, $path, $val) = @_;
  return $self->_param($path => $val);
}
 
sub exists {
  my ($self, $path) = @_;
  my $code = $self->{exists};
  my $key  = $self->name($path);

  return $self->$code($key);
}

sub delete {
  my ($self, $path) = @_;
  my $code = $self->{delete};
  my $key  = $self->name($path);

  return $self->$code($key);
}

sub keys {
  my ($self, $path) = @_;

  my $method = $self->{method};
  my @names  = $self->param_store->$method;

  my %is_key;

  PATH: for my $name (@names) {
    my $this_path = $self->parsed_path($name);

    next unless @$this_path > @$path;

    for my $i (0 .. $#$path) {
      next PATH unless $this_path->[$i] eq $path->[$i];
    }

    $is_key{ $this_path->[ $#$path + 1 ] } = 1;
  }

  return keys %is_key;
}

1;
