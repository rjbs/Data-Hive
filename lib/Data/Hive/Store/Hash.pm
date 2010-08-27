use strict;
use warnings;
package Data::Hive::Store::Hash;
# ABSTRACT: store a hive in nested hashrefs

=head1 DESCRIPTION

This is a simple store, primarily for testing, that will store hives in nested
hashrefs.  All hives are represented as hashrefs, and their values are stored
in the entry for the empty string.

So, we could do this:

  my $href = {};

  my $hive = Data::Hive->NEW({
    store_class => 'Hash',
    store_args  => [ $href ],
  });

  $hive->foo->SET(1);
  $hive->foo->bar->baz->SET(2);

We would end up with C<$href> containing:

  {
    foo => {
      ''  => 1,
      bar => {
        baz => {
          '' => 2,
        },
      },
    },
  }

Using empty keys results in a bigger, uglier dump, but allows a given hive to
contain both a value and subhives.

=method new

  my $store = Data::Hive::Store::Hash->new(\%hash);

The only argument expected for C<new> is a hashref, which is the hashref in
which hive entries are stored.

If no hashref is provided, a new, empty hashref will be used.

=cut

sub new {
  my ($class, $href) = @_;
  $href = {} unless defined $href;

  return bless { store => $href } => $class;
}

=method get

Use given C<< \@path >> as nesting keys in the hashref store.

=cut

sub _die {
  require Carp::Clan;
  Carp::Clan->import('^Data::Hive($|::)');
  croak(shift);
}

my $BREAK = "BREAK\n";
my $LAST  = "LAST\n";

sub _descend {
  my ($self, $path, $arg) = @_;
  my @path = @$path;
  $arg ||= {};
  $arg->{step} or die "step is required";
  $arg->{cond} ||= sub { @{ shift() } };
  $arg->{end}  ||= sub { $_[0] };

  my $node = $self->{store};
  while ($arg->{cond}->(\@path)) {
    my $seg = shift @path;

    {
      local $SIG{__DIE__};
      eval { $arg->{step}->($seg, $node, \@path) };
    }

    return if $@ and $@ eq $BREAK;
    die $@ if $@;
    $node = $node->{$seg} ||= {};
  }

  return $arg->{end}->($node, \@path);
}

sub get {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, {
      step => sub {
        my ($seg, $node) = @_;
        if (defined $node and not ref $node) {
          _die("can't get key '$seg' of non-ref value '$node'");
        }
        die $BREAK unless exists $node->{$seg};
      }
    }
  );
}

=method set

See C<L</get>>.  Dies if you try to set a key underneath an existing
non-hashref key, e.g.:

  $hash = { foo => 1 };
  $store->set([ 'foo', 'bar' ], 2); # dies

=cut

sub set {
  my ($self, $path, $value) = @_;
  return $self->_descend(
    $path, {
      step => sub {
        my ($seg, $node, $path) = @_;
        if (exists $node->{$seg} and not ref $node->{$seg}) {
          _die("can't overwrite existing non-ref value: '$node->{$seg}'");
        }
      },
      cond => sub { @{ shift() } > 1 },
      end  => sub {
        my ($node, $path) = @_;
        $node->{$path->[0]} = $value;
      },
    },
  );
}

=method name

Returns a string, potentially suitable for eval-ing, describing a hash
dereference of a variable called C<< $STORE >>.

  "$STORE->{foo}->{bar}"

This is probably not very useful.

=cut

sub name {
  my ($self, $path) = @_;
  return join '->', '$STORE', map { "{'$_'}" } @$path;
}

=method exists

Descend the hash and return false if any of the path's parts do not exist, or
true if they all do.

=cut

sub exists {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, { 
      step => sub {
        my ($seg, $node) = @_;
        die $BREAK unless exists $node->{$seg};
      },
    },
  );
}  

=method delete

Descend the hash and delete the given path.  Only deletes the leaf.

=cut

sub delete {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, {
      step => sub {
        my ($seg, $node) = @_;
        die $BREAK unless exists $node->{$seg};
      },
      cond => sub { @{ shift() } > 1 },
      end  => sub {
        my ($node, $path) = @_;
        delete $node->{$path->[0]};
      },
    },
  );
}

1;
