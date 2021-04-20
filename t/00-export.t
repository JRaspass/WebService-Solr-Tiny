use strict;
use warnings;

use Test::Fatal;
use Test::More tests => 4;

package t::default { use WebService::Solr::Tiny }

is_deeply [ sort keys %t::default:: ], ['BEGIN'];

package t::empty { use WebService::Solr::Tiny () }

is_deeply [ sort keys %t::empty:: ], ['BEGIN'], '()';

package t::explicit { use WebService::Solr::Tiny 'solr_escape' }

is_deeply [ sort keys %t::explicit:: ], [qw/BEGIN solr_escape/], '"solr_escape"';

is exception { WebService::Solr::Tiny->import('foo') }, <<EXP, '"foo"';
"foo" is not exported by the WebService::Solr::Tiny module
Can't continue after import errors at ${\__FILE__} line ${\( __LINE__ - 2 )}.
EXP
