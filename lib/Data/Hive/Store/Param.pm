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

List of characters to escape (via URI encoding) in keys.

Defaults to the C<< separator >>.

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
  my $escape = $self->{escape} or return $str;
  $str =~ s/([\Q$escape\E%])/sprintf("%%%x", ord($1))/ge;
  return $str;
}

sub _path {
  my ($self, $path) = @_;
  return join $self->{separator}, map { $self->_escape($_) } @$path;
}

sub new {
  my ($class, $obj, $arg) = @_;
  $arg              ||= {};
  $arg->{escape}    ||= $arg->{separator} || '.';
  $arg->{separator} ||= substr($arg->{escape}, 0, 1);
  $arg->{method}    ||= 'param';
  $arg->{exists}    ||= sub { exists $obj->{shift()} };
  $arg->{delete}    ||= sub { delete $obj->{shift()} };
  $arg->{obj}         = $obj;
  return bless { %$arg } => $class;
}

sub _param {
  my $self = shift;
  my $meth = $self->{method};
  my $path = $self->_path(shift);
  return $self->{obj}->$meth($path, @_);
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
  return $self->_path($path);
}

sub exists {
  my ($self, $path) = @_;
  my $code = $self->{exists};
  my $key = $self->_path($path);
  return ref($code) ? $code->($key) : $self->{obj}->$code($key);
}

sub delete {
  my ($self, $path) = @_;
  my $code = $self->{delete};
  my $key = $self->_path($path);

  return $self->{obj}->$code($key);
}

sub keys {
  my ($self, $path) = @_;

  my $method = $self->{method};
  my @names  = $self->{obj}->$method;

  my $name = $self->_path($path);

  my $sep = $self->{separator};

  my $start = length $name ? "$name$sep" : q{};
  my %seen  = map { /\A\Q$start\E(.+?)(\z|\Q$sep\E)/ ? ($1 => 1) : () } @names;

  my @keys = map { URI::Escape::uri_unescape($_) } keys %seen;
  return @keys;
}

=head1 BUGS

The interaction between escapes and separators is not very well formalized or
tested.  If you change things much, you'll probably be frustrated.

Fixes and/or tests would be lovely.

=cut

1;
