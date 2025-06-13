#!perl
use strict;
use warnings;
use version;

use Test::More;

use Imager::zxing;

my $v = version->new(Imager::zxing->version);

my @types = Imager::zxing::Encoder->availFormats;

my %type_strs =
  (
    "EAN-8" => "96385074",   # 8 characters
    "ITF" => "0123456789", # even count
    "UPC-A" => "485963095124", # 11 or 12 digits
    "UPC-E" => "0509689", # 6 digits
   );

diag "Types @types\n";
for my $type (@types) {
  my $e = Imager::zxing::Encoder->new($type);

  my $text = $type_strs{$type};
  defined $text or $text = "9781975344054";
  my $im = $e->encode($text, 100, 100);
  my $msg = Imager->errstr;
  ok($im, "make a $type")
    or diag "Error for $type: ".Imager->errstr;
}

done_testing();
