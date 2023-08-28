package Imager::zxing;
use strict;
use warnings;
use Imager;

our $VERSION;
BEGIN {
  $VERSION = "1.000";
  use XSLoader;
  XSLoader::load("Imager::zxing" => $VERSION);
}

1;

=head1 NAME

Imager::zxing - decode barcodes from Imager images using libzxing

=head1 SYNOPSIS

  use Imager::zxing;
  my $decoder = Imager::zxing::Decoder->new;
  # list accepted formats separated by '|'
  print $decoder->formats;
  # list available formats
  print $decoder->avail_formats
  # set the accepted formats
  $decoder->set_formats("DataMatrix|QRCode")
    or die $decoder->error;

  # decode any barcodes
  my $im = Imager->new(file => "somefile.png");
  my @results = $decoder->decoder($im);

  for my $result (@results) {
    print $result->text, "\n";
  }

=head1 DESCRIPTION

A primitive wrapper around zxing-cpp

Currently only supports decoding and doesn't expand much of the
interface.

=head1 LICENSE

Imager::zxing is licensed under the same terms as perl itself.

=cut
