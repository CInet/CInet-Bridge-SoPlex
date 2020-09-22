use v5.14;
use strict;
use warnings;

use bignum; # need exact arithmetic to verify soplex's exact arithmetic
use IPC::Run3;
use Path::Tiny;

use Test::More;
use CInet::Bridge::SoPlex qw(soplex);

# This is an inequality description of the cone of polymatroids on a ground
# set of five elements. It is a rational polyhedral cone in dimension 32.
#
# Its face lattice is antiisomorphic to the lattice of semimatroids, which
# are conditional independence structures which resemble entropy vectors.
# We test soplex by letting it decide whether CI structures are semimatroids
# or not, which is equivalent to finding a relatively interior point on the
# face described by a given conditional independence structure.
#
# The first 80 inequalities define the inequalities define the relevant
# facets of the cone from the point of view of conditional independence
# (neglecting functional dependence). A conditional independence structure
# is given by a string of exactly 80 characters which are "0" and "1".
# A "0" makes the inequality tight whereas a "1" makes it strict, which,
# since it is a rational polyhedral cone, is equivalent to ">= 1".
my @polymatroids = (
    [ [ -1, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 1, -1 ], '>=', 0 ],
    [ [ -1, 1, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 1, -1 ], '>=', 0 ],
    [ [ -1, 1, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, -1 ], '>=', 0 ],
    [ [ -1, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, -1 ], '>=', 0 ],
    [ [ -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1 ], '>=', 0 ],
    [ [ -1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, -1 ], '>=', 0 ],
    [ [ -1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, -1 ], '>=', 0 ],
    [ [ -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, -1 ], '>=', 0 ],
    [ [ -1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, -1 ], '>=', 0 ],
    [ [ -1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, -1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, -1 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1 ], '>=', 0 ],
    [ [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1 ], '>=', 0 ],
    [ [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], '=', 0 ],
);

# Write the system in .lp format
sub write_system {
    my $in = Path::Tiny->tempfile;
    my $fh = $in->openw_utf8;
	say {$fh} "Minimize";
	say {$fh} " obj: " . join(' + ', map { "x$_" } 1 .. 80);
    say {$fh} "Subject To";
    for (@_) {
        my ($h, $rel, $val) = @$_;
        my @c;
        for my $i (1 .. 80) {
            my $v = $h->[$i-1];
            next if $v == 0;
            push @c, ($v < 0 ? '-' : '+'), abs($v), "x$i";
        }
        push @c, $rel, $val;
        say {$fh} ' ', join(' ', @c);
	}
    say {$fh} "End";
    close $fh;
    $in
}

# Get a vector of either the primal solution or the dual Farkas ray.
# The length of the certificate must be given.
sub extract_certificate {
    my ($len, $start, $end, $var, $out) = @_;
    my $cert = [ map { 0 } 1 .. $len ];
    for (split /\n/, $out) {
        if (/$start/ .. /$end/) {
            next unless /^$var(\d+)\s*(.+)$/;
            my ($nr, $val) = ($1, $2);
            $cert->[$nr - 1] = eval $val;
        }
    }
    $cert
}

# Check that $sol is feasible for @$system.
sub check_feasible {
    my ($sol, $system) = @_;
    # @$system encodes A*x @rels b where @rels are '=' or '>=' constraints.
    # Now $sol is x and we just check if these constraints are satisfied.
    for my $i (1 .. @$system) {
        local $_ = $system->[$i-1];
        my $row = $_->[0];
        my $ax = 0;
        $ax += $row->[$_-1] * $sol->[$_-1] for 1 .. @$row;
        my $rel = $_->[1];
        $rel = '==' if $rel eq '=';
        cmp_ok($ax, $rel, $_->[2], "row $i is satisfied");
    }
}

# Check that $sol is feasible for the Farkas-dual to @$system.
sub check_infeasible {
    my ($sol, $system) = @_;
    # @$system encodes A*x @rels b where @rels are '=' or '>=' constraints.
    # Infeasibility of this system guarantees, by Farkas's lemma, a solution
    # y (which is $sol now) such that: A^T*y = 0 and b^T*y > 0 and where
    # for each '>=' constraint the corresponding entry y_i is >= 0.
    my $by = 0;
    my $ATy = [ map { 0 } 1 .. 80 ];
    for my $i (1 .. @$system) {
        local $_ = $system->[$i-1];
        my $row = $_->[0];
        $by += $_->[2] * $sol->[$i-1];
        cmp_ok($sol->[$i-1], '>=', '0', "entry $i is non-negative") if $_->[1] eq '>=';
        $ATy->[$_-1] += $sol->[$i-1] * $row->[$_-1] for 1 .. @$ATy;
    }
    cmp_ok($ATy->[$_-1], '==', 0, "ray is orthogonal to the rowspan ($_)") for 1 .. @$ATy;
    cmp_ok($by, '>', 0, "contradiction found");
}

sub check_semimatroid {
    my ($A, $expected) = @_;
    my @system = @polymatroids;
    # Modify the system to describe a rational cone in the interior of
    # the face defined by $A which contains all of the face's lattice
    # points, as per the explanation above.
    for my $i (1 .. 80) {
        if (substr($A, $i, 1) eq '0') {
            $system[$i]->[1] = '=';
            $system[$i]->[2] = '0';
        }
        else {
            $system[$i]->[1] = '>=';
            $system[$i]->[2] = '1';
        }
    }

    my $in = write_system @system;
    run3 [soplex, '-f0', '-o0', '-X', '-Y', $in], \undef, \my $out, \my $err;
    my $status = $? >> 8;
    die "soplex exited with status $status:\n$err" if $status != 0;

    $out =~ /SoPlex status\s*: problem is solved \[(.+?)\]/m;
    my $word = $1;

    if ($expected) {
        is $word, 'optimal', 'problem feasible';
        my $sol = extract_certificate(80, qr/^Primal solution/ => qr/All other|^$/ => 'x' => $out);
        check_feasible $sol, \@system;
    }
    else {
        is $word, 'infeasible', 'problem infeasible';
        my $ray = extract_certificate(0+ @system, qr/^Dual ray/ => qr/All other|^$/ => 'C' => $out);
        check_infeasible $ray, \@system;
    }
}

# First test: this is a Bayesian network, so a semimatroid.
# The DAG is
#   1 --> 2 --> 5
#   |           ^
#   v           |
#   3 --> 4 ----´
check_semimatroid('11111111111111111101011011110010101101101001011111111111111111111111100011111111' => 1);
# Second test: this is the Vamos gaussoid and not a semimatroid.
check_semimatroid('01111111110111111110111111110111111011111111111011111101111101111011111111011111' => 0);

# TODO: More feasibility tests. Also test optimal value (bounded and unbounded).

done_testing;
