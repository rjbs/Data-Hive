use strict;
use warnings;
package Data::Hive::PathPacker::Strict;

use Carp ();

=begin :list

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

=end :list

=cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $guts = {
    separator => $arg->{separator} || '.',
  };

  return bless $guts => $class;
}

sub pack_path {
  my ($self, $path) = @_;

  my $sep     = $self->{separator};
  my @illegal = grep { /\Q$sep\E/ } @$path;

  Carp::confess("illegal hive path parts: @illegal") if @illegal;

  return join $sep, @$path;
}

sub unpack_path {
  my ($self, $str) = @_;

  my $sep = $self->{separator};
  return [ split /\Q$sep\E/, $str ];
}

1;
