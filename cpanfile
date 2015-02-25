configure_requires 'Module::Build::Tiny';

requires 'Carp';
requires 'HTTP::Tiny';
requires 'JSON::MaybeXS';
requires 'Moo';
requires 'URI';

on test => sub {
    requires 'Test::Fatal';
    requires 'Test::MockObject';
    requires 'Test::More';
};
