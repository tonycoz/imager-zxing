#define ZX_USE_UTF8
#include "ReadBarcode.h"
#include "GTIN.h"
#include "ZXVersion.h"
#include <memory>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"

using namespace ZXing;

// typemap support
using std_string = std::string;
using std_string_view = std::string_view;

#define string_to_SV(str, flags) string_to_SVx(aTHX_ (str), (flags))
static inline SV *
string_to_SVx(pTHX_ const std::string &str, U32 flags) {
  SV *sv = newSVpvn_flags(str.data(), str.size(), flags);

  // in theory at least, the decoded strings are UTF-8
  // in C++20 that would mean std::u8string but zxing doesn't seem to use that yet
  sv_utf8_decode(sv);

  return sv;
}

static std::unique_ptr<uint8_t[]>
get_image_data(i_img *im, ImageFormat &format) {
  int channels = im->channels < 3 ? 1 : 3;
  size_t row_size = im->xsize * channels;
  auto data{std::make_unique<uint8_t[]>(im->ysize * row_size)};

  auto datap = data.get();
  for (i_img_dim y = 0; y < im->ysize; ++y) {
    i_gsamp(im, 0, im->xsize, y, datap, nullptr, channels);
    datap += row_size;
  }

  format = channels == 1 ? ImageFormat::Lum : ImageFormat::RGB;
  return data;
}

struct ZXingDecoder {
  ZXingDecoder() {
    hints.setFormats(BarcodeFormats::all());
#if ZXING_VERSION_MAJOR >= 2
    hints.setTextMode(TextMode::HRI);
#endif
    hints.setEanAddOnSymbol(EanAddOnSymbol::Read);
  }
  std::string formats() const {
    return ToString(hints.formats());
  }
  // modern zxing takes a string_view here, but 1.4 wants a string /cry
  // and doesn't try to convert it
  bool
  set_formats(const std::string &formats) {
    try {
      hints.setFormats(BarcodeFormatsFromString(formats));
      return true;
    }
    catch (std::exception &e) {
      m_error = e.what();
      return false;
    }
  }
  Results
  decode(i_img *im) const {
    ImageFormat format;
    auto imdata = get_image_data(im, format);
    ImageView image(imdata.get(), im->xsize, im->ysize, format);

    return ReadBarcodes(image, hints);
  }

  std::string
  error() const {
    return m_error;
  }

  static std::vector<std::string>
  avail_formats() {
    std::vector<std::string> formats;
    for (auto f : BarcodeFormats::all()) {
      formats.emplace_back(ToString(f));
    }
    return formats;
  }

  DecodeHints hints;
  std::string m_error;
};

struct ZXingDecoderResult {
  ZXingDecoderResult(Result&&r): m_result(r) {}
  std::string text() const {
    return m_result.text();
  }
  bool is_valid() const {
    return m_result.isValid();
  }
  bool is_mirrored() const {
    return m_result.isMirrored();
  }
  bool is_inverted() const {
#if ZXING_MAJOR_VERSION >= 2
    return m_result.isInverted();
#else
    return false;
#endif
  }
  std::string format() const {
    return ToString(m_result.format());
  }
  std::string content_type() const {
    return ToString(m_result.contentType());
  }
  Position position() const {
    return m_result.position();
  }
  int orientation() const {
    return m_result.orientation();
  }
  Result m_result;
};

#define Q_(x) #x
#define Q(x) Q_(x)

#define zx_version() \
  Q(ZXING_VERSION_MAJOR) "." Q(ZXING_VERSION_MINOR) "." Q(ZXING_VERSION_PATCH)

enum bool_options {
  bo_try_harder = 1,
  bo_try_downscale,
  bo_pure,
  bo_try_code39_extended_mode,
  bo_validate_code39_checksum,
  bo_validate_itf_checksum,
  bo_return_codabar_start_end,
  bo_return_errors,
  bo_try_rotate,
  bo_try_invert
};

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::zxing PACKAGE = Imager::zxing PREFIX=zx_
PROTOTYPES: DISABLE

const char *
zx_version(...)
  C_ARGS:

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder PREFIX=ZXingDecoder::

ZXingDecoder *
ZXingDecoder::new()

void
ZXingDecoder::DESTROY()

std_string
ZXingDecoder::formats() const

bool
ZXingDecoder::set_formats(std_string formats)

void
ZXingDecoder::decode(Imager im) const
  PPCODE:
    auto results = THIS->decode(im);
    EXTEND(SP, results.size());
    for (auto &&r : results) {
      auto pr = new ZXingDecoderResult(std::move(r));
      SV *sv_r = sv_newmortal();
      sv_setref_pv(sv_r, "Imager::zxing::Decoder::Result", pr);
      PUSHs(sv_r);
    }

std_string
ZXingDecoder::error() const

static void
ZXingDecoder::avail_formats()
  PPCODE:
    const auto &v = ZXingDecoder::avail_formats();
    EXTEND(SP, v.size());
    for (auto &f : v) {
      PUSHs(string_to_SV(f, SVs_TEMP));
    }

void
ZXingDecoder::set_try_harder(bool val)
  ALIAS:
    set_try_harder = bo_try_harder
    set_try_downscale = bo_try_downscale
    set_pure = bo_pure
    set_try_code39_extended_mode = bo_try_code39_extended_mode
    set_validate_code39_checksum = bo_validate_code39_checksum
    set_validate_itf_checksum = bo_validate_itf_checksum
    set_return_codabar_start_end = bo_return_codabar_start_end
    set_return_errors = bo_return_errors
    set_try_rotate = bo_try_rotate
    set_try_invert = bo_try_invert
  CODE:
    switch (static_cast<bool_options>(ix)) {
    case bo_try_harder:
      THIS->hints.setTryHarder(val);
      break;
    case bo_try_downscale:
      THIS->hints.setTryDownscale(val);
      break;
    case bo_pure:
      THIS->hints.setIsPure(val);
      break;
    case bo_try_code39_extended_mode:
      THIS->hints.setTryCode39ExtendedMode(val);
      break;
    case bo_validate_code39_checksum:
      THIS->hints.setValidateCode39CheckSum(val);
      break;
    case bo_validate_itf_checksum:
      THIS->hints.setValidateITFCheckSum(val);
      break;
    case bo_return_codabar_start_end:
      THIS->hints.setReturnCodabarStartEnd(val);
      break;
    case bo_return_errors:
      THIS->hints.setReturnErrors(val);
      break;
    case bo_try_rotate:
      THIS->hints.setTryRotate(val);
      break;
    case bo_try_invert:
#if ZXING_VERSION_MAJOR >= 2
      THIS->hints.setTryInvert(val);
#else
      Perl_croak(aTHX_ "set_try_invert requires zxing-cpp 2.0.0 or later");
#endif
      break;
    }

bool
ZXingDecoder::try_harder()
  ALIAS:
    try_harder = bo_try_harder
    try_downscale = bo_try_downscale
    pure = bo_pure
    try_code39_extended_mode = bo_try_code39_extended_mode
    validate_code39_checksum = bo_validate_code39_checksum
    validate_itf_checksum = bo_validate_itf_checksum
    return_codabar_start_end = bo_return_codabar_start_end
    return_errors = bo_return_errors
    try_rotate = bo_try_rotate
    try_invert = bo_try_invert
  CODE:
    switch (static_cast<bool_options>(ix)) {
    case bo_try_harder:
      RETVAL = THIS->hints.tryHarder();
      break;
    case bo_try_downscale:
      RETVAL = THIS->hints.tryDownscale();
      break;
    case bo_pure:
      RETVAL = THIS->hints.isPure();
      break;
    case bo_try_code39_extended_mode:
      RETVAL = THIS->hints.tryCode39ExtendedMode();
      break;
    case bo_validate_code39_checksum:
      RETVAL = THIS->hints.validateCode39CheckSum();
      break;
    case bo_validate_itf_checksum:
      RETVAL = THIS->hints.validateITFCheckSum();
      break;
    case bo_return_codabar_start_end:
      RETVAL = THIS->hints.returnCodabarStartEnd();
      break;
    case bo_return_errors:
      RETVAL = THIS->hints.returnErrors();
      break;
    case bo_try_rotate:
      RETVAL = THIS->hints.tryRotate();
      break;
    case bo_try_invert:
#if ZXING_VERSION_MAJOR >= 2
      RETVAL = THIS->hints.tryInvert();
#else
      Perl_croak(aTHX_ "try_invert requires zxing-cpp 2.0.0 or later");
#endif
      break;
    }
  OUTPUT: RETVAL

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder::Result PREFIX = ZXingDecoderResult::

std_string
ZXingDecoderResult::text() const

void
ZXingDecoderResult::DESTROY()

bool
ZXingDecoderResult::is_valid() const

bool
ZXingDecoderResult::is_mirrored() const

bool
ZXingDecoderResult::is_inverted() const

std_string
ZXingDecoderResult::format() const

std_string
ZXingDecoderResult::content_type() const

void
ZXingDecoderResult::position() const
  PPCODE:
    auto pos = THIS->position();
    EXTEND(SP, 8);
    for (auto &f : pos) {
      PUSHs(sv_2mortal(newSViv(f.x)));
      PUSHs(sv_2mortal(newSViv(f.y)));
    }

int
ZXingDecoderResult::orientation() const

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;
