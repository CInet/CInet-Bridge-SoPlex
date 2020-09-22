=encoding utf8

=head1 NAME

CInet::Bridge::SoPlex - Make C<soplex> available one way or another

=head1 SYNOPSIS

    use IPC::Run3;
    use CInet::Bridge::SoPlex qw(soplex);

    # Compute exact rational solution to linear program
    run3 [soplex, '-f0', '-o0', '-l0', '-X', $lp_file], \undef, \my $out;

=head2 VERSION

This document describes CInet::Bridge::Soplex v1.0.0.

=cut

our $VERSION = "v1.0.0";

=head1 DESCRIPTION

L<SoPlex|https://soplex.zib.de> is a fantastic LP solver developed at
Zuse Institute Berlin. In particular for our applications in L<CInet|https://conditional-independence.net>
its promise to compute exact arbitrary precision rational solutions when
asked for is crucial for the certifiability of computations in the theory
of conditional independence using methods of discrete geometry.

However, the L<ZIB Academic License|https://www.scipopt.org/academic.txt>
under which SoPlex is released imposes conditions on the redistribution of
its source code which I cannot commit to (particularly clause 3c).

For our convenience, I wrote a module C<CInet::Alien::SoPlex> which,
like L<CInet::Alien::CaDiCaL> and friends, statically compiles a C<soplex>
executable suitable to CInet's needs (that is, statically compiled and
with GMP support). That module bundles SoPlex's source code and cannot
be redistributed.

The present module only exists to either pull our internal module in as a
"recommends"-level dependency or ensure that a suitable C<soplex> binary
is already installed on-site. Unless you are me, ask your system administrator
to install SoPlex and ensure that you are in full compliance with its license.

=cut

# ABSTRACT: Make soplex available one way or another
package CInet::Bridge::SoPlex;

use Modern::Perl 2018;
use Carp;

use File::Which;

=head1 EXPORTS

There is one optional export:

=head2 soplex

    use CInet::Bridge::SoPlex qw(soplex);
    my $program = soplex;

Returns the absolute path of a C<soplex> executable or dies if none is found.
If available, C<CInet::Alien::SoPlex> is preferred over examining C<$PATH>.

=cut

our @EXPORT_OK = qw(soplex);
use Exporter qw(import);

sub soplex {
    state $soplex = do {
        my $exe = eval {
            require 'CInet::Alien::SoPlex';
            CInet::Alien::SoPlex->exe
        };
        $exe //= which 'soplex';

        croak 'soplex could not be found'
            if not defined $exe;
        $exe
    }
}

=head1 SEE ALSO

=over

=item *

The SoPlex website is L<https://soplex.zib.de/index.php>.
SoPlex is part of the L<SCIP optimization suite|https://scipopt.org/>
developed at Zuse Institute Berlin. See the article L<The SCIP Optimization suite|https://nbn-resolving.de/urn:nbn:de:0297-zib-69361>
and cite it if your work relies on it.

=item *

If you use SoPlex or SCIP, you must fulfill the conditions of the
L<ZIB Academic License|https://scipopt.org/academic.txt>!

=item *

If you use SoPlex as an exact rational LP solver, you should cite
in addition L<Improving the Accuracy of Linear Programming Solvers with Iterative Refinement|https://nbn-resolving.de/urn:nbn:de:0297-zib-15451>
and L<Iterative Refinement for Linear Programming|https://nbn-resolving.de/urn:nbn:de:0297-zib-55118>.

=back

=head1 TODO

In the future, I will consider the option provided in clause 8 to make
this bridging module obsolete.

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
