package WebService::Solr::Tiny 0.002;

use v5.20;
use warnings;
use experimental qw/postderef signatures/;

use Exporter 'import';
use URI::Query::FromHash 0.003;

our @EXPORT_OK = 'solr_escape';

sub new ( $class, %args ) {
    my $self = bless \%args, $class;

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

sub search ( $self, $q = '', %args ) {
    my $reply = $self->{agent}->get( $self->{url} . '?' .
        hash2query { $self->{default_args}->%*, 'q' => $q, %args } );

    unless ( $reply->{success} ) {
        require Carp;

        Carp::croak("Solr request failed - $reply->{content}");
    }

    $self->{decoder}( $reply->{content} );
}

sub solr_escape ( $q ) { $q =~ s/([\Q+-&|!(){}[]^"~*?:\\\E])/\\$1/gr }

no URI::Query::FromHash;

1;
