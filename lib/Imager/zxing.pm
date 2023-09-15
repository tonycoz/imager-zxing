package Imager::zxing;
use strict;
use warnings;
use Imager;

our $VERSION;
BEGIN {
  $VERSION = "1.001";
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
  my @results = $decoder->decode($im);

  for my $result (@results) {
    print $result->text, "\n";
  }

=head1 DESCRIPTION

A primitive wrapper around zxing-cpp

This requires at least 1.4.0 of zxing-cpp, but 2.1.0 is preferable.

Currently only supports decoding and doesn't expose much of the
interface.

To use this:

=over

=item 1.

Create a decoder object:

  use Imager::zxing;
  my $decoder = Imager::zxing::Decoder->new;

=item 2.

Configure it if needed, most likely by setting the accepted barcode
encodings:

  $decoder->set_formats("DataMatrix|QRCode");

=item 3.

Load an image using Imager:

  my $img = Imager->new(file => "somename.png")
    or die "Cannot load image ", Imager->errstr;

The available file formats depends on the libraries Imager was built
with.

=item 4.

Decode the barcode:

  my @results = $decoder->decode($img)
    or die "No barcodes found";

=item 5.

Process the results:

  for my $r (@results) {
    print $r->format, ": ", $r->text, "\n";
  }

=back

=head1 Imager::zxing::Decoder class methods

=over

=item * new

  my $decoder = Imager::zxing::Decoder->new;

Create a new decoder object, does not accept any parameters.

Default is to process all available barcode formats.

=item * avail_formats

  my @formats = Imager::zxing::Decoder->avail_formats

Returns a list of the barcode formats that are decodable.

=back

=head1 Decoder object methods

Create a decoder with:

  my $decoder = Imager::zxing::Decoder->new;

=head2 Decoding

=over

=item * decode(image)

Attempts to decode barcodes from the supplied Imager image object.

Returns a list of result objects, or an empty list if none are found.

  my $img = Imager->new(file => "somefile.png") or die Imager->errstr;
  my @results = $decoder->decode($img);

=back

=head2 Settings

=over

=item * formats()

Returns the formats the decoder accepts as a C<|> separated string.

  print $decoder->formats
  # default output:
  # Aztec|Codabar|Code39|Code93|Code128|DataBar|DataBarExpanded|DataMatrix|EAN-8|EAN-13|ITF|MaxiCode|PDF417|QRCode|UPC-A|UPC-E|MicroQRCode

=item * set_formats(formats)

Sets the barcode formats that the decoder will decode, as a space,
C<|> or comma separated string.

  $decoder->set_formats("DataMatrix|QRCode");

=back

There are various boolean options that can be set with set_I<option>(I<val>) setting the option and I<option>() returning the current value.

=over

=item * C<try_harder>

Spend more time to try to find a barcode; optimize for accuracy, not
speed.

  $decoder->set_try_harder(0); # a bit faster
  my $val = $decoder->try_harder;

Default: true.

=item * C<try_downscale>

Also try detecting code in downscaled images (depending on image size).

  $decoder->set_try_downscale(0); # a bit faster
  my $val = $decoder->try_harder;

Default: true.

=item * C<pure>)

Set to non-zero to only accept results where the image is an aligned
image where the image is only the barcode.

  $decoder->set_pure(1);
  my $val = $decoder->pure();

Default: false.

Note: this appears to be non-functional in my testing, this accepted a
rotated image.

=item * C<try_code39_extended_mode>

If true, the Code-39 reader will try to read extended mode.

  $decoder->set_try_code39_extended_mode(0);
  my $val = $decoder->try_code39_extended_mode();

Default: false.

=item * C<validate_code39_checksum>

Assume Code-39 codes employ a check digit and validate it.

  $decoder->validate_code39_checksum(1);
  my $val = $decoder->validate_code39_checksum;

Default: false.

=item * C<validate_itf_checksum>

  $decoder->set_validate_itf_checksum(1);
  my $val = $decoder->validate_itf_checksum();

Assume ITF codes employ a GS1 check digit and validate it.

Default: false.

=item * C<return_codabar_start_end>

If true, return the start and end chars in a Codabar barcode instead
of stripping them.

  $decoder->set_return_codabar_start_end(1);
  my $val = $decoder->return_codabar_start_end();

Default: false.

=item * C<return_errors>

Set to non-zero to include results with soft errors such as checksum
errors.

Default: false.

  $decoder->set_return_errors(1);
  my $val = $decoder->return_errors();

=item * C<try_rotate>

Also try detecting code in 90, 180 and 270 degree rotated images.

  $decoder->set_try_rotate(1);
  my $val = $decoder->try_rotate();

Default: true.

=item * C<try_invert>

Also try detecting inverted ("reversed reflectance") codes if the
format allows for those.

  $decoder->set_try_invert(1);
  my $val = $decoder->try_invert();

Default: true.  Requires zxing-cpp 2.0.0 or later.

=back

=head1 Result object methods

Result objects are returned by the decoder decode() method:

  my @results = $decoder->decode($image);

=over

=item * text()

Returns the decoded text.

  my $text = $result->text;

=item * is_valid()

True if the result represents a valid decoded barcode.

=item * is_mirrored()

True if the result is from a mirrored barcode.

=item * is_inverted()

True if the barcode image has inverted dark/light.  Requires zxing
2.0.0 to be valid.

=item * format()

The format of the decoded barcode.

=item * position()

The co-ordinates of the top left, top right, bottom left and bottom
right points of the decoded barcode in the supplied image, as a list.

=item * orientation()

The rotation of the barcode image in degrees.

=back

=head1 LICENSE

Imager::zxing is licensed under the same terms as perl itself.

=cut
