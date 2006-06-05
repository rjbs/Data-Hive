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

A Data::Hive::Store object, or an object that implements its
C<< get >>, C<< set >>, and C<< name >> methods.

=item * store_class

Class to instantiate C<< $store >> from.  The classname will
have 'Data::Hive::Store::' prepended; to avoid this, prefix
it with a '+' ('+My::Store').  Mutually exclusive with the C<<
store >> option.

=item * store_args

Arguments to instantiate C<< $store >> with.  Mutually
exclusive with the C<< store >> option.

=back

=cut

sub NEW {
  my ($class, $arg) = @_;
  $arg ||= {};
  $arg->{path} ||= [];
  my $self = bless $arg => ref($class) || $class;

  if ($self->{store_class} and $self->{store_args}) {
    die "don't use 'store' with 'store_class' and 'store_args'" if $self->{store};
    $self->{store_class} = "Data::Hive::Store::$self->{store_class}"
      unless $self->{store_class} =~ s/^\+//;
    $self->{store} = $self->{store_class}->new(@{ $self->{store_args} });
    delete @{$self}{qw(store_class store_args)};
  }

  return $self;
}

=head2 GET

Retrieve the value represented by this object's path from the store.

=head2 GETNUM

Soley for Perl 5.6.1 compatability, where returning undef
from overloaded numification causes a segfault.

=cut

use overload (
  q{""}    => 'GET',
  q{0+}    => 'GETNUM',
  fallback => 1,
);

sub GET {
  my $self = shift;
  return $self->{store}->get($self->{path});
}

sub GETNUM { shift->GET || 0 }

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

1; # End of Data::Hive