use strict;
use warnings;

use Test::More tests => 1;
use WebService::Solr::Tiny;

is_deeply [ sort keys %WebService::Solr::Tiny:: ] => [ qw/
    BEGIN EXPORT EXPORT_OK VERSION __ANON__
    import new search solr_escape solr_query
/];
