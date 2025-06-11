#!perl
use strict;
use warnings;
use version;

use Test::More;

use Imager::zxing;

my $v = version->new(Imager::zxing->version);

my @types = Imager::zxing::Decoder->availFormats; # FIXME

diag "Types @types\n";
for my $type (@types) {
  my $e = Imager::zxing::Encoder->new($type);

  my $im = $e->encode("9781975344054", 100, 100);
  ok($im, "make a $type");
}

done_testing();
