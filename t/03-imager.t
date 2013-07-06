#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Chess::Rep::Coverage::Imager') }

my $g = eval { Chess::Rep::Coverage::Imager->new() };
print $@ if $@;
isa_ok $g, 'Chess::Rep::Coverage::Imager';

my $fen = '8/8/3p4/4k3/8/8/8/8 w ---- - 0 1'; # Black pawn & king - king protects but pawn doesn't
diag($fen);
$g->set_from_fen($fen);
my $c = $g->coverage();
my $b = $g->board();
isa_ok $b, 'Imager';
#my $f = $g->write('board', 'png');
#ok $f && -s $f > 0, 'wrote board image';
