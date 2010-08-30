use strict;
use warnings;
package Data::Hive::Store::Param;
# ABSTRACT: CGI::param-like store for Data::Hive

use URI::Escape ();

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

= escape

This should be a coderef that will escape each part of the path before joining
them with C<join>.  It will be called like this:

  my $escaped_part = do {
    local $_ = $path_part;
    $store->$escape( $path_part );
  }

The default escape routine URI encodes non-word characters.

= separator

String to join path segments together with; defaults to either the first
character of the C<< escape >> option (if given) or '.'.

= exists

Coderef that describes how to see if a given parameter name (C<< separator
>>-joined path) exists.  The default is to treat the object like a hashref and
look inside it.

= delete

Coderef that describes how to delete a given parameter name.  The default is to
treat the object like a hashref and call C<delete> on it.

=end :list

=cut

sub _escape {
  my ($self, $str) = @_;

  $str =~ s/([^a-z0-9_])/sprintf("%%%x", ord($1))/gie;

  return $str;
}

sub _unescape {
  my ($self, $str) = @_;

  URI::Escape::uri_unescape($str);
}

sub escaped_path {
  my ($self, $path) = @_;

  my $escape = $self->{escape};
  my $join   = $self->{join};

  return $self->$join([ map {; $self->$escape($_) } @$path ]);
}

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

    escape    => $arg->{escape}   || \&_escape,
    unescape  => $arg->{unescape} || \&_unescape,

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
  my $path = $self->escaped_path(shift);
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
 
sub name {
  my ($self, $path) = @_;
  return $self->escaped_path($path);
}

sub exists {
  my ($self, $path) = @_;
  my $code = $self->{exists};
  my $key  = $self->escaped_path($path);

  return $self->$code($key);
}

sub delete {
  my ($self, $path) = @_;
  my $code = $self->{delete};
  my $key  = $self->escaped_path($path);

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

=head1 BUGS

The interaction between escapes and separators is not very well formalized or
tested.  If you change things much, you'll probably be frustrated.

Fixes and/or tests would be lovely.

=cut

1;
