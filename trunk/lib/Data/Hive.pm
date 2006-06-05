package Data::Hive;

use warnings;
use strict;

=head1 NAME

Data::Hive - convenient access to hierarchical data

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Hive;

    my $hive = Data::Hive->NEW(\%arg);
    print $hive->foo->bar->baz;
    $hive->foo->bar->quux->SET(17);

=head1 METHODS

=head2 NEW

arguments:

=over

=item * store

=back

=cut

sub NEW {
  my ($class, $arg) = @_;
  $arg ||= {};
  $arg->{path} ||= [];
  my $self = bless $arg => ref($class) || $class;
}

=head2 GET

=cut

use overload (
  q{""} => 'GET',
  q{0+} => 'GET',
  fallback => 1,
);

sub GET {
  my $self = shift;
  return $self->{store}->get($self->{path});
}

=head2 SET

=cut

sub SET {
  my $self = shift;
  return $self->{store}->set($self->{path}, @_);
}

=head2 NAME

=cut

sub NAME {
  my $self = shift;
  return $self->{store}->name($self->{path});
}

=head2 ITEM

=cut

sub ITEM {
  my ($self, $key) = @_;
  return $self->NEW({
    %$self,
    path => [ @{$self->{path}}, $key ],
  });
}

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  (my $method = $AUTOLOAD) =~ s/.*:://;
  die "AUTOLOAD for '$method' called on non-object" unless ref $self;
  return if $method eq 'DESTROY';
  return $self->ITEM($method);
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-hive at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hive>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Hive

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Hive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Hive>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hive>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Hive>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Data::Hive::Store::Hash;

sub new {
  my ($class, $hash) = @_;
  return bless \$hash => $class;
}

sub get {
  my ($self, $path) = @_;
  my $hash = $$self;
  while (@$path) {
    my $seg = shift @$path;
    return unless exists $hash->{$seg};
    $hash = $hash->{$seg};
  }
  return $hash;
}

sub set {
  my ($self, $path, $key) = @_;
  my $hash = $$self;
  while (@$path > 1) {
    my $seg = shift @$path;
    if (exists $hash->{$seg} and not ref $hash->{$seg}) {
      die "can't overwrite existing non-ref value: '$hash->{$seg}'"
    }
    $hash = $hash->{$seg} ||= {};
  }
  $hash->{$path->[0]} = $key;
}

sub name {
  my ($self, $path) = @_;
  return join '->', '$store', map { "{$_}" } @$path;
}

package Data::Hive::Store::Accountinfo;

sub _escape {
  my $str = shift;
  $str =~ s/\./\\./g;
  return $str;
}

sub _unescape {
  my $str = shift;
  $str =~ s/\\\././g;
  return $str;
}

sub _path {
  my $path = shift;
  return join '.', map { _escape($_) } @$path;
}

sub new {
  my ($class, $account) = @_;
  return bless \$account => $class;
}

sub get {
  my ($self, $path) = @_;
  return $$self->info(_path($path));
}

sub set {
  my ($self, $path, $val) = @_;
  return $$self->info(_path($path) => $val);
}
 
sub name {
  my ($self, $path) = @_;
  return _path($path);
}

1; # End of Data::Hive
