use strict;
use warnings;

use Test::More tests => 1;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new;

my %got = %WebService::Solr::Tiny::;

# AUTOLOAD seems to have disappeared between 5.16 & 5.18.
# It is not important for this test so delete it.
delete $got{AUTOLOAD};

is_deeply [ sort keys %got ], [ qw/
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
