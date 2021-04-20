# NAME

WebService::Solr::Tiny - Perl interface to Apache Solr

<div>

    <a href=https://github.com/JRaspass/WebService-Solr-Tiny/actions/workflows/test.yml>
        <img src=https://github.com/JRaspass/WebService-Solr-Tiny/actions/workflows/test.yml/badge.svg></a>
    <a href=https://coveralls.io/r/JRaspass/WebService-Solr-Tiny>
        <img src=https://coveralls.io/repos/JRaspass/WebService-Solr-Tiny/badge.svg></a>
    <a href=https://metacpan.org/pod/WebService::Solr::Tiny>
        <img src=https://img.shields.io/cpan/v/WebService-Solr-Tiny.svg></a>
    <a href=https://github.com/JRaspass/WebService-Solr-Tiny/issues>
        <img src=https://img.shields.io/github/issues/JRaspass/WebService-Solr-Tiny.svg></a>
</div>

# SYNOPSIS

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

# DESCRIPTION

WebService::Solr::Tiny is similar to, and inspired by [WebService::Solr](https://metacpan.org/pod/WebService::Solr),
but with an aim to be tinier.

# FUNCTIONS

The functions in this section are exportable on request.

## solr\_escape

`solr_escape` is a small utility subroutine for escaping characters that
have meaning in Lucene query syntax.

## solr\_query

`solr_query` aims to make it easier for users of [WebService::Solr](https://metacpan.org/pod/WebService::Solr) to
migrate to this distribution. It takes the same arguments as the constructor
of a [WebService::Solr::Query](https://metacpan.org/pod/WebService::Solr::Query) object, and returns a string that is
equivalent to stringifying that object.

# METHODS

## new

Construct a new WebService::Solr::Tiny instance. The constructor takes the
following parameters:

- `agent`

    The HTTP user-agent to use to make the requests. Defaults to an [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny)
    instance.

- `decoder`

    A code reference to use for decoding responses. Defaults to using
    `decode_json` from [JSON::PP](https://metacpan.org/pod/JSON::PP).

- `default_args`

    A hash reference with default parameters that will be passed along as part of
    every request. The values in this hash will be merged with those passed to
    `search`. Defaults to an empty hash reference.

- `url`

    The URL of the collection requests will be sent to. Defaults to
    `http://localhost:8983/solr/select`.

## search

Sends a request to Solr. Takes a string to be used as a Solr query, and an
optional list of key-value pairs to be used as additional query parameters to
qualify the request.

The query defaults to the empty string, and will be passed as the `q` query
parameter. No special protections are in place to prevent any of the additional
arguments from overwriting this.

If any value has been set as part of the `default_args` in the constructor,
these will be merged with the arguments to this function.

The final set of parameters will be converted to a query parameter string
using [URI::Query::FromHash](https://metacpan.org/pod/URI::Query::FromHash). See that module's documentation for more
details about how these values will be processed.

In the event of a failure of any kind, this function will croak with the
content of the response.

On success, the full content of the response will be passed to the code ref
specified in the `decoder` parameter to the constructor, and the result of
this will be this method's return value.

# PERFORMANCE

One way to increase the performance of this module is to swap out the decoder.
By default Solr returns JSON, therefore the fastest decoder for this would be
[JSON::XS](https://metacpan.org/pod/JSON::XS). You can swap out [JSON::PP](https://metacpan.org/pod/JSON::PP) for [JSON::XS](https://metacpan.org/pod/JSON::XS) like so:

    use JSON::XS ();
    use WebService::Solr::Tiny;

    my $solr = WebService::Solr::Tiny->new( decoder => \&JSON::XS::decode_json );

However it's possible to make Solr return a compact binary format known as
JavaBin, to do so we send `wt=javabin` with each request. Couple that with
the CPAN module [JavaBin](https://metacpan.org/pod/JavaBin) like so:

    use JavaBin ();
    use WebService::Solr::Tiny;

    my $solr = WebService::Solr::Tiny->new(
        decoder      => \&JavaBin::from_javabin,
        default_args => { wt => 'javabin' },
    );

Both of these should be faster than the stock configuration, but require a C
compiler and are generally not as portable, YMMV so benchmark first.

# SEE ALSO

[WebService::Solr](https://metacpan.org/pod/WebService::Solr)

# COPYRIGHT AND LICENSE

Copyright © 2015 by James Raspass

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
