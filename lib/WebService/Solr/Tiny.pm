package WebService::Solr::Tiny 0.001;

use Carp 'croak';
use Moo;

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
        require JSON::MaybeXS;

        \&JSON::MaybeXS::decode_json;
    },
);

has default_args => ( is => 'ro', default => sub { {} } );

has url => (
    is      => 'ro',
    default => sub {
        require URI;

        URI->new('http://localhost:8983/solr/select')
    },
);

sub search {
    my $self = shift;
    my $url  = $self->url->clone;

    $url->query_form( %{ $self->default_args }, 'q' => @_ );

    my $reply = $self->agent->get($url);

    croak "Solr request failed - $reply->{content}" unless $reply->{success};

    $self->decoder->( $reply->{content} );
}

1;
