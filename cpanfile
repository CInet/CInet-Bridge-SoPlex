requires 'Modern::Perl', '>= 1.20180000';
requires 'Carp';

requires 'File::Which';

recommends 'CInet::Alien::SoPlex';

on 'test' => sub {
    requires 'Path::Tiny';
    requires 'IPC::Run3';
    requires 'Test::More';
};
