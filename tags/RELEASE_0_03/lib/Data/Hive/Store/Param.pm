package Data::Hive::Store::Param;

use strict;
use warnings;

=head1 NAME

Data::Hive::Store::Param

=head1 DESCRIPTION

CGI-like param() store for Data::Hive.

=head1 METHODS

=head2 new

  # use default method name 'param'
  my $store = Data::Hive::Store::Param->new($obj);

  # use different method name 'info'
  my $store = Data::Hive::Store::Param->new($obj, { method => 'info' });

  # escape certain characters in keys
  my $store = Data::Hive::Store::Param->new($obj, { escape => './!' });

Return a new param() store.

Several interesting arguments can be passed in a hashref
after the first (mandatory) object argument.

=over 

=item * method

Use a different method name on the object (default is 'param').

=item * escape

List of characters to escape (prepend '\' to) in keys.

Defaults to the C<< separator >>.

=item * separator

String to join path segments together with; defaults to
either the first character of the C<< escape >> option (if
given) or '.'.

=item * exists

Coderef that describes how to see if a given parameter name
(C<< separator >>-joined path) exists.  The default is to
treat the object like a hashref and look inside it.

=back

=cut

sub _escape {
  my ($self, $str) = @_;
  my $escape = $self->{escape} or return $str;
  $str =~ s/([$escape])/\\$1/g;
  return $str;
}

sub _path {
  my ($self, $path) = @_;
  return join $self->{separator}, map { $self->_escape($_) } @$path;
}

=head2 new

  my $store = Data::Hive::Store::Param->new($obj, \%arg);

=cut

sub new {
  my ($class, $obj, $arg) = @_;
  $arg              ||= {};
  $arg->{escape}    ||= $arg->{separator} || '.';
  $arg->{separator} ||= substr($arg->{escape}, 0, 1);
  $arg->{method}    ||= 'param';
  $arg->{exists}    ||= sub { exists $obj->{shift()} };
  $arg->{obj}         = $obj;
  return bless { %$arg } => $class;
}

sub _param {
  my $self = shift;
  my $meth = $self->{method};
  my $path = $self->_path(shift);
  return $self->{obj}->$meth($path, @_);
}

=head2 get

Join the path together with the C<< separator >> and get it
from the object.

=cut

sub get {
  my ($self, $path) = @_;
  return $self->_param($path);
}

=head2 set

See L</get>.

=cut

sub set {
  my ($self, $path, $val) = @_;
  return $self->_param($path => $val);
}

=head2 name

Join path together with C<< separator >> and return it.

=cut
 
sub name {
  my ($self, $path) = @_;
  return $self->_path($path);
}

=head2 exists

Return true if the C<< name >> of this hive is a parameter.

=cut

sub exists {
  my ($self, $path) = @_;
  my $code = $self->{exists};
  my $key = $self->_path($path);
  return ref($code) ? $code->($key) : $self->{obj}->$code($key);
}

1;
