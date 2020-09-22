use strict;
use warnings;

use Test::More;
use IPC::Run3;

use CInet::Bridge::SoPlex qw(soplex);

run3 [soplex, '--version'], \undef, \my $out, \my $err;

TODO: {
    local $TODO = "nice to have but not fatal if not";

    is($? >> 8, 0, '--version is understood');
    is($err, '', 'no error output');
    like($out, qr/SoPlex version ([0-9.a-z]+)/, 'version format');
    like($out, qr/\[rational: GMP [0-9.a-z]+\]/, 'rational arithmetic supported');
}

done_testing;
