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

# deprecated names
*Imager::zxing::Decoder::set_pure =
  \&Imager::zxing::Decoder::setIsPure;
*Imager::zxing::Decoder::set_return_errors =
  \&Imager::zxing::Decoder::setReturnErrors;

*Imager::zxing::Decoder::Result::is_valid =
  \&Imager::zxing::Decoder::Result::isValid;
*Imager::zxing::Decoder::Result::is_mirrored =
  \&Imager::zxing::Decoder::Result::isMirrored;
*Imager::zxing::Decoder::Result::is_inverted =
  \&Imager::zxing::Decoder::Result::isInverted;
*Imager::zxing::Decoder::Result::content_type =
  \&Imager::zxing::Decoder::Result::contentType;

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

There are various boolean options that can be set with
setI<option>(I<val>) setting the option and I<option>() returning the
current value.

=over

=item * C<tryHarder>

Spend more time to try to find a barcode; optimize for accuracy, not
speed.

  $decoder->setTryHarder(0); # a bit faster
  my $val = $decoder->tryHarder;

Default: true.

=item * C<tryDownscale>

Also try detecting code in downscaled images (depending on image size).

  $decoder->setTryDownscale(0); # a bit faster
  my $val = $decoder->tryDownscale;

Default: true.

=item * C<isPure>)

Set to non-zero to only accept results where the image is an aligned
image where the image is only the barcode.

  $decoder->setIsPure(1);
  my $val = $decoder->isPure();

Default: false.

Note: this appears to be non-functional in my testing, this accepted a
rotated image.

This could previously be set with set_pure(), which has been renamed
to better match the C++ API.

=item * C<tryCode39ExtendedMode>

If true, the Code-39 reader will try to read extended mode.

  $decoder->setTryCode39ExtendedMode(0);
  my $val = $decoder->tryCode39ExtendedMode();

Default: false.

=item * C<validateCode39CheckSum>

Assume Code-39 codes employ a check digit and validate it.

  $decoder->validateCode39CheckSum(1);
  my $val = $decoder->validateCode39CheckSum;

Default: false.

=item * C<validateITFCheckSum>

  $decoder->setValidateITFCheckSum(1);
  my $val = $decoder->validateITFCheckSum();

Assume ITF codes employ a GS1 check digit and validate it.

Default: false.

=item * C<returnCodabarStartEnd>

If true, return the start and end chars in a Codabar barcode instead
of stripping them.

  $decoder->setReturnCodabarStartEnd(1);
  my $val = $decoder->returnCodabarStartEnd();

Default: false.

=item * C<returnErrors>

Set to non-zero to include results with soft errors such as checksum
errors.

Default: false.

  $decoder->setReturnErrors(1);
  my $val = $decoder->returnErrors();

This could previously be set with set_return_errors() which is now
deprecated to better match the C++ API.

=item * C<tryRotate>

Also try detecting code in 90, 180 and 270 degree rotated images.

  $decoder->setTryRotate(1);
  my $val = $decoder->tryRotate();

Default: true.

=item * C<tryInvert>

Also try detecting inverted ("reversed reflectance") codes if the
format allows for those.

  $decoder->setTryInvert(1);
  my $val = $decoder->tryInvert();

Default: true.  Requires zxing-cpp 2.0.0 or later.

=back

=head1 Result object methods

Result objects are returned by the decoder decode() method:

  my @results = $decoder->decode($image);

=over

=item * text()

Returns the decoded text.

  my $text = $result->text;

=item * isValid()

True if the result represents a valid decoded barcode.

Replaces the deprecated is_valid() method.

=item * isMirrored()

True if the result is from a mirrored barcode.

Replaces the deprecated is_mirrored() method.

=item * isInverted()

True if the barcode image has inverted dark/light.  Requires zxing
2.0.0 to be valid.

Replaces the deprecated is_inverted() method.
=item * format()

The format of the decoded barcode.

=item * position()

The co-ordinates of the top left, top right, bottom left and bottom
right points of the decoded barcode in the supplied image, as a list.

=item * orientation()

The rotation of the barcode image in degrees.

=back

=head1 DEPRECATIONS

The following method names from Imager::zxing::Decoder are deprecated,
and listed here with their replacements:

=over

=item set_pure()

Replaced by setIsPure().

=item set_return_errors()

Replaced by setReturnErrors().

=back

The following method names from Imager::zxing::Decoder::Result are
deprecated and listed here with their replacements:

=over

=item content_type()

Replaced by contentType()

=item is_mirrored()

Replaced by isMirrored()

=item is_valid()

Replaced by isValid()

=item is_inverted()

Replaced by isInverted().

=back

These have been renamed to better match the C++ API.  The old names
are available without warning for now, but will produce a default-on
warning in a future release and removed at some point after that.

=head1 LICENSE

Imager::zxing is licensed under the same terms as perl itself.

=head1 SEE ALSO

Imager

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=cut
