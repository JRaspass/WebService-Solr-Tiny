package WebService::Solr::Tiny 0.002;

use v5.20;
use warnings;
use experimental qw/lexical_subs postderef signatures/;

use Exporter 'import';
use URI::Query::FromHash 0.003;

our @EXPORT_OK = qw/solr_escape solr_query/;

sub new ( $class, %args ) {
    my $self = bless \%args, $class;

    $self->{agent}        //=
        do { require HTTP::Tiny; HTTP::Tiny->new( keep_alive => 1 ) };
    $self->{decoder}      //=
        do { require JSON::PP; \&JSON::PP::decode_json };
    $self->{default_args} //= {};
    $self->{url}          //= 'http://localhost:8983/solr/select';

    $self;
}

sub search ( $self, $q = '', %args ) {
    my $reply = $self->{agent}->get( $self->{url} . '?' .
        hash2query { $self->{default_args}->%*, q => $q, %args } );

    unless ( $reply->{success} ) {
        require Carp;

        Carp::croak("Solr request failed - $reply->{content}");
    }

    $self->{decoder}( $reply->{content} );
}

sub solr_escape ( $q ) { $q =~ s/([\Q+-&|!(){}[]^"~*?:\\\E])/\\$1/gr }

# For solr_query
my ( %struct, %value, %op );
sub solr_query ( $x ) { $struct{ARRAY}->( ref $x eq 'ARRAY' ? $x : [ $x ] ) }

my sub dispatch ( $table, $name, @args ) {
    ( $table->{$name} // die "Cannot dispatch to $name" )->(@args);
}

my sub pair ( $k, $v ) {
    # If it's an array ref, the first element MAY be an operator:
    #   [ -and => { -require => 'X' }, { -require => 'Y' } ]
    if ( ref $v eq 'ARRAY' && ( $v->[0] // '' ) =~ /^-(AND|OR)$/i ) {
        my ( $op, undef, @val ) = ( uc $1, @$v );
        return sprintf '(%s)',
            join " $op ", map '(' . $struct{HASH}->({ $k => $_ }) . ')', @val;
    }

    dispatch( \%value, ref $v || 'SCALAR', $k, $v );
}

$struct{HASH} = sub( $x ) {
    join ' AND ', map {
        /^-(.+)/ ? dispatch( \%op, $1, $x->{$_} ) : pair( $_, $x->{$_} )
    } sort keys %$x;
};

$struct{ARRAY} = sub ( $x ) {
    '(' . join( ' OR ', map dispatch( \%struct, ref $_, $_ ), @$x ) . ')';
};

$value{SCALAR} = sub ( $k, $v ) {
    my $value = ref $v ? $$v : ( '"' . solr_escape($v) . '"' );
    "$k:$value" =~ s/^://r;
};

$value{HASH} = sub ( $k, $v ) {
    join ' AND ',
        map dispatch( \%op, s/^-(.+)/$1/r, $k, $v->{$_} ), sort keys %$v;
};

$value{ARRAY} = sub ( $k, $v ) {
    '(' . join( ' OR ', map $value{SCALAR}->( $k, $_ ), @$v ) . ')';
};

$op{default}   = sub (     $v ) { pair( '', $v ) };
$op{require}   = sub ( $k, $v ) { qq(+$k:") . solr_escape($v) . '"' };
$op{prohibit}  = sub ( $k, $v ) { qq(-$k:") . solr_escape($v) . '"' };
$op{range}     = sub ( $k, $v ) { "$k:[$v->[ 0 ] TO $v->[ 1 ]]" };
$op{range_exc} = sub ( $k, $v ) { "$k:{$v->[ 0 ] TO $v->[ 1 ]}" };
$op{range_inc} = $op{range};

$op{boost} = sub ( $k, $extra ) {
    my ( $v, $boost ) = @$extra;
    sprintf '%s:"%s"^%s', $k, solr_escape($v), $boost;
};

$op{fuzzy} = sub ( $k, $extra ) {
    my ( $v, $dist ) = @$extra;
    sprintf '%s:%s~%s', $k, solr_escape($v), $dist;
};

$op{proximity} = sub ( $k, $extra ) {
    my ( $v, $dist ) = @$extra;
    sprintf '%s:"%s"~%s', $k, solr_escape($v), $dist;
};

no URI::Query::FromHash;

1;

__END__

=encoding UTF-8

=head1 NAME

WebService::Solr::Tiny - Perl interface to Apache Solr

=for html
<a href=https://github.com/JRaspass/WebService-Solr-Tiny/actions/workflows/test.yml>
    <img src=https://github.com/JRaspass/WebService-Solr-Tiny/actions/workflows/test.yml/badge.svg></a>
<a href=https://coveralls.io/r/JRaspass/WebService-Solr-Tiny>
    <img src=https://coveralls.io/repos/JRaspass/WebService-Solr-Tiny/badge.svg></a>
<a href=https://metacpan.org/pod/WebService::Solr::Tiny>
    <img src=https://img.shields.io/cpan/v/WebService-Solr-Tiny.svg></a>
<a href=https://github.com/JRaspass/WebService-Solr-Tiny/issues>
    <img src=https://img.shields.io/github/issues/JRaspass/WebService-Solr-Tiny.svg></a>

=head1 SYNOPSIS

 use WebService::Solr::Tiny 'solr_escape';

 my $solr = WebService::Solr::Tiny->new;

 # Simple
 $solr->search('foo');

 # Complex
 $solr->search(
     '{!lucene q.op=AND df=text}myfield:foo +bar -baz',
     debugQuery => 'true',
     fl         => 'id,name,price',
     fq         => [
         'foo:"' . solr_escape($foo) . '"',
         'popularity:[10 TO *]',
         'section:0',
     ],
     omitHeader => 'true',
     rows       => 20,
     sort       => 'inStock desc, price asc',
     start      => 10,
 );

=head1 DESCRIPTION

WebService::Solr::Tiny is similar to, and inspired by L<WebService::Solr>,
but with an aim to be tinier.

=head1 FUNCTIONS

The functions in this section are exportable on request.

=head2 solr_escape

C<solr_escape> is a small utility subroutine for escaping characters that
have meaning in Lucene query syntax.

=head2 solr_query

C<solr_query> aims to make it easier for users of L<WebService::Solr> to
migrate to this distribution. It takes the same arguments as the constructor
of a L<WebService::Solr::Query> object, and returns a string that is
equivalent to stringifying that object.

=head1 METHODS

=head2 new

Construct a new WebService::Solr::Tiny instance. The constructor takes the
following parameters:

=over

=item C<agent>

The HTTP user-agent to use to make the requests. Defaults to an L<HTTP::Tiny>
instance.

=item C<decoder>

A code reference to use for decoding responses. Defaults to using
C<decode_json> from L<JSON::PP>.

=item C<default_args>

A hash reference with default parameters that will be passed along as part of
every request. The values in this hash will be merged with those passed to
C<search>. Defaults to an empty hash reference.

=item C<url>

The URL of the collection requests will be sent to. Defaults to
C<http://localhost:8983/solr/select>.

=back

=head2 search

Sends a request to Solr. Takes a string to be used as a Solr query, and an
optional list of key-value pairs to be used as additional query parameters to
qualify the request.

The query defaults to the empty string, and will be passed as the C<q> query
parameter. No special protections are in place to prevent any of the additional
arguments from overwriting this.

If any value has been set as part of the C<default_args> in the constructor,
these will be merged with the arguments to this function.

The final set of parameters will be converted to a query parameter string
using L<URI::Query::FromHash>. See that module's documentation for more
details about how these values will be processed.

In the event of a failure of any kind, this function will croak with the
content of the response.

On success, the full content of the response will be passed to the code ref
specified in the C<decoder> parameter to the constructor, and the result of
this will be this method's return value.

=head1 PERFORMANCE

One way to increase the performance of this module is to swap out the decoder.
By default Solr returns JSON, therefore the fastest decoder for this would be
L<JSON::XS>. You can swap out L<JSON::PP> for L<JSON::XS> like so:

 use JSON::XS ();
 use WebService::Solr::Tiny;

 my $solr = WebService::Solr::Tiny->new( decoder => \&JSON::XS::decode_json );

However it's possible to make Solr return a compact binary format known as
JavaBin, to do so we send C<wt=javabin> with each request. Couple that with
the CPAN module L<JavaBin> like so:

 use JavaBin ();
 use WebService::Solr::Tiny;

 my $solr = WebService::Solr::Tiny->new(
     decoder      => \&JavaBin::from_javabin,
     default_args => { wt => 'javabin' },
 );

Both of these should be faster than the stock configuration, but require a C
compiler and are generally not as portable, YMMV so benchmark first.

=head1 SEE ALSO

L<WebService::Solr>

=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by James Raspass

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
