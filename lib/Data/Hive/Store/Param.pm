use strict;
use warnings;
package Data::Hive::Store::Param;
# ABSTRACT: CGI::param-like store for Data::Hive

use parent 'Data::Hive::Store';

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

= path_packer

This is an object providing the L<Data::Hive::PathPacker> interface.  It will
convert a string to a path (arrayref) or the reverse.  It defaults to a
L<Data::Hive::PathPacker::Strict>.

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

sub path_packer { $_[0]{path_packer} }

sub name { $_[0]->path_packer->pack_path($_[1]) }

sub new {
  my ($class, $obj, $arg) = @_;
  $arg ||= {};

  my $guts = {
    obj         => $obj,

    path_packer => $arg->{path_packer} || do {
      require Data::Hive::PathPacker::Strict;
      Data::Hive::PathPacker::Strict->new;
    },

    method      => $arg->{method} || 'param',

    exists      => $arg->{exists} || sub {
      my ($self, $key) = @_;
      my $method = $self->{method};
      my $exists = grep { $key eq $_ } $self->param_store->$method;
      return ! ! $exists;
    },

    delete      => $arg->{delete} || sub {
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
    my $this_path = $self->path_packer->unpack_path($name);

    next unless @$this_path > @$path;

    for my $i (0 .. $#$path) {
      next PATH unless $this_path->[$i] eq $path->[$i];
    }

    $is_key{ $this_path->[ $#$path + 1 ] } = 1;
  }

  return keys %is_key;
}

1;
