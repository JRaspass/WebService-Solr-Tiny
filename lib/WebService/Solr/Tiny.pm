package WebService::Solr::Tiny 0.001;

use Carp 'croak';
use Moo;
use URI::Query::FromHash;

use namespace::clean;

has agent => (
    is      => 'ro',
    default => sub {
        require HTTP::Tiny;

        HTTP::Tiny->new( keep_alive => 1 );
    },
);

has decoder => (
    is      => 'ro',
    default => sub {
        require JSON::PP;

        \&JSON::PP::decode_json;
    },
);

has default_args => ( is => 'ro', default => sub { {} } );

has url => ( is => 'ro', default => 'http://localhost:8983/solr/select' );

sub search {
    my $self = shift;
    my %args = ( %{ $self->default_args }, 'q' => @_ ? @_ : '' );

    my $reply = $self->agent->get( $self->url . '?' . hash2query %args );

    croak "Solr request failed - $reply->{content}" unless $reply->{success};

    $self->decoder->( $reply->{content} );
}

1;
