package WebService::Solr::Tiny 0.001;

use strict;
use warnings;

use URI::Query::FromHash ();

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;

    unless ( exists $self->{agent} ) {
        require HTTP::Tiny;

        $self->{agent} = HTTP::Tiny->new( keep_alive => 1 );
    }

    unless ( exists $self->{decoder} ) {
        require JSON::PP;

        $self->{decoder} = \&JSON::PP::decode_json;
    }

    $self->{default_args} //= {};
    $self->{url}          //= 'http://localhost:8983/solr/select';

    $self;
}

sub search {
    my $self = shift;
    my %args = ( %{ $self->{default_args} }, 'q' => @_ ? @_ : '' );

    my $reply = $self->{agent}->get(
        $self->{url} . '?' . URI::Query::FromHash::hash2query(%args) );

    unless ( $reply->{success} ) {
        require Carp;

        Carp::croak("Solr request failed - $reply->{content}");
    }

    $self->{decoder}( $reply->{content} );
}

my $esc = sub { shift =~ s/([\Q+-&|!(){}[]^"~*?:\\\E])/\\$1/gr };

my %ops = (
    -boost     => sub {       $_[0] . ':"' . $esc->( $_[1] ) . '"^' . $_[2] },
    -fuzzy     => sub {       $_[0] . ':'  . $esc->( $_[1] ) . '~'  . $_[2] },
    -proximity => sub {       $_[0] . ':"' . $esc->( $_[1] ) . '"~' . $_[2] },

    -prohibit  => sub { '-' . $_[0] . ':"' . $esc->( $_[1] ) . '"' },
    -require   => sub { '+' . $_[0] . ':"' . $esc->( $_[1] ) . '"' },

    -range_exc => sub { "$_[0]:{$_[1] TO $_[2]}" },
    -range_inc => sub { "$_[0]:[$_[1] TO $_[2]]" },
);

my %dispatch;
   %dispatch = (
    ARRAY => sub {
        '(' . join( ' OR ', map $dispatch{+ref}($_), @{ +shift } ) . ')';
    },
    HASH => sub {
        my $struct = shift;

        join ' AND ', map {
            my $k = $_ eq '-default' ? '' : $_;
            my $v = $struct->{$_};

            ### it's an array ref, the first element MAY be an operator!
            ### it would look something like this:
            # [ '-and',
            #   { '-require' => 'star' },
            #   { '-require' => 'wars' }
            # ];
            if ( ref $v eq 'ARRAY' && $v->[0] =~ /^-(AND|OR)$/i ) {
                '(' . join(
                    " \U$1 ",
                    map '(' . $dispatch{HASH}( { $k => $_ } ) . ')', @$v[ 1.. $#$v ]
                ) . ')';
            }
            else {
                if ( ref $v eq 'ARRAY' ) {
                    '(' . join(
                        ' OR ',
                        map {
                            ( $k . ':' . ( ref ? $$_ : '"' . $esc->($_) . '"' ) )
                            =~ s/^://r
                        } @$v
                    ) . ')';
                }
                elsif ( ref $v eq 'HASH' ) {
                    join ' AND ', map {
                        my $v = $v->{$_};

                        $ops{$_}( $k, ref $v ? @$v : $v );
                    } sort keys %$v;
                }
                else {
                    ( $k . ':' . ( ref $v ? $$v : '"' . $esc->($v) . '"' ) )
                        =~ s/^://r;
                }
            }
        } sort keys %$struct;
    },
);

sub import {
    no strict 'refs';

    *{ caller . '::solr_query' } = \&solr_query;
}

sub solr_query {
    $dispatch{ARRAY}( @_ == 1 && ref $_[0] eq 'ARRAY' ? $_[0] : \@_ );
}

1;
