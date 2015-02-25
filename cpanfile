requires 'Carp';
requires 'Moo';

recommends 'HTTP::Tiny';
recommends 'JSON::MaybeXS';
recommends 'URI';

on test => sub {
    requires 'Test::Fatal';
    requires 'Test::MockObject';
    requires 'Test::More';
};
