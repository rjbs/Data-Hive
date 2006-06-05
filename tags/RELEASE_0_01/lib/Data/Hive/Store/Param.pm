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

sub new {
  my ($class, $obj, $arg) = @_;
  $arg              ||= {};
  $arg->{escape}    ||= $arg->{separator} || '.';
  $arg->{separator} ||= substr($arg->{escape}, 0, 1);
  $arg->{method}    ||= 'param';
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

1;
