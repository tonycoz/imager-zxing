#!perl
use strict;
use warnings;

use Test::More;

use Imager::zxing;

my $d = Imager::zxing::Decoder->new;
my $im = Imager->new(file => "t/simple.ppm")
  or die "Cannot load t/simple.ppm: ", Imager->errstr;

my @r = $d->decode($im);
ok(@r, "got results");
is($r[0]->text, "Imager::zxing", "got expected result");

done_testing();
