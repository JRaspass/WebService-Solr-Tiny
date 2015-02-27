use strict;
use warnings;

use Test::More tests => 1;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new;

my %got = %WebService::Solr::Tiny::;

# We only want to test what methods we've added, remove standard perl ones.
delete @got{ qw/
    AUTOLOAD
    BEGIN
    BUILD
    BUILDARGS
    DEMOLISH
    ISA
    VERSION
    __ANON__
    import
    can
/ };

# __NAMESPACE_CLEAN_STORAGE is an implementation detail because we use
# namespace::clean, it would be nicer not to leave that in the namespace.
is_deeply [ sort keys %got ], [ qw/
    __NAMESPACE_CLEAN_STORAGE
    agent
    decoder
    default_args
    new
    search
    url
/ ], "package doesn't leave too many imports in it";
