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
contain both a value and subhives.  B<Please note> that this is different
behavior compared with earlier releases, in which empty keys were not used and
it was not legal to have a value and a hive at a given path.  It is possible,
although fairly unlikely, that this format will change again.  The Hash store
should generally be used for testing things that use a hive, as opposed for
building hashes that will be used for anything else.

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

=method hash_store

This method returns the hashref in which things are being used.  You should not
alter its contents!

=cut

sub hash_store {
  $_[0]->{store}
}

sub _die {
  require Carp::Clan;
  Carp::Clan->import('^Data::Hive($|::)');
  croak(shift);
}

my $BREAK = "BREAK\n";

# Wow, this is quite a little machine!  Here's a slightly simplified overview
# of what it does:  -- rjbs, 2010-08-27
#
# As long as cond->(\@remaining_path) is true, execute step->($next,
# $current_hashref, \@remaining_path)
#
# If it dies with $BREAK, stop looping and return.  Once the cond returns
# false, return end->($current_hashref, \@remaining_path)
sub _descend {
  my ($self, $orig_path, $arg) = @_;
  my @path = @$orig_path;

  $arg ||= {};
  $arg->{step} or die "step is required";
  $arg->{cond} ||= sub { @{ shift() } };
  $arg->{end}  ||= sub { $_[0] };

  my $node = $self->hash_store;

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
      end  => sub { $_[0]->{''} },
      step => sub {
        my ($seg, $node) = @_;

        if (defined $node and not ref $node) {
          # We found a bogus entry in the store! -- rjbs, 2010-08-27
          _die("can't get key '$seg' of non-ref value '$node'");
        }

        die $BREAK unless exists $node->{$seg};
      }
    }
  );
}

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
        $node->{$path->[0]}{''} = $value;
      },
    },
  );
}

=method name

The name returned by the Hash store is a string, potentially suitable for
eval-ing, describing a hash dereference of a variable called C<< $STORE >>.

  "$STORE->{foo}->{bar}"

This is probably not very useful.

=cut

sub name {
  my ($self, $path) = @_;
  return join '->', '$STORE', map { "{'$_'}" } @$path;
}

sub exists {
  my ($self, $path) = @_;
  return $self->_descend(
    $path, { 
      step => sub {
        my ($seg, $node) = @_;
        die $BREAK unless exists $node->{$seg};
      },
      end  => sub { return exists $_[0]->{''}; },
    },
  );
}  

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
        my ($node, $final_path) = @_;
        my $this = $node->{ $final_path->[0] };
        my $rv = delete $this->{''};

        # Cleanup empty trees after deletion!  It would be convenient to have
        # ->_ascend, but I'm not likely to bother with writing it just yet.
        # -- rjbs, 2010-08-27
        $self->_descend(
          $path, {
            step => sub {
              my ($seg, $node) = @_;
              return if keys %{ $node->{$seg} };
              delete $node->{$seg};
              die $BREAK;
            },
          }
        );

        return $rv;
      },
    },
  );
}

sub keys {
  my ($self, $path) = @_;

  return $self->_descend($path, {
    step => sub {
      my ($seg, $node) = @_;
      die $BREAK unless exists $node->{$seg};
    },
    end  => sub {
      return grep { length } keys %{ $_[0] };
    },
  });
}

1;
