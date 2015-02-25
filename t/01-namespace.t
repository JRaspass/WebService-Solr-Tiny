use strict;
use warnings;

use Test::More tests => 1;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new;

is_deeply [ sort keys %WebService::Solr::Tiny:: ], [ qw/
    BEGIN
    BUILD
    BUILDARGS
    DEMOLISH
    ISA
    VERSION
    __ANON__
    __NAMESPACE_CLEAN_STORAGE
    agent
    can
    decoder
    default_args
    import
    new
    search
    url
/ ], "package doesn't leave too many imports in it";
