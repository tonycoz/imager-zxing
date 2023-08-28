#define ZX_USE_UTF8
#include "ReadBarcode.h"
#include "GTIN.h"
#include "ZXVersion.h"
#include <optional>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"

using namespace ZXing;

struct decoder {
  DecodeHints hints;
  std::string error;
};

static decoder *
dec_new() {
  decoder *dec = new decoder();
  dec->hints.setFormats(BarcodeFormats::all());
#if ZXING_MAJOR_VERSION >= 2
  dec->hints.setTextMode(TextMode::HRI);
#endif
  dec->hints.setEanAddOnSymbol(EanAddOnSymbol::Read);

  return dec;
}

static void
dec_DESTROY(decoder *dec) {
  delete dec;
}

#define dec_formats(dec) dec_formatsx(aTHX_ (dec))
static SV *
dec_formatsx(pTHX_ decoder *dec) {
  auto str = ToString(dec->hints.formats());
  return newSVpvn(str.data(), str.size());
}

static bool
dec_set_formats(decoder *dec, const char *formats) {
  try {
    dec->hints.setFormats(BarcodeFormatsFromString(formats));
    return true;
  }
  catch (std::exception &e) {
    dec->error = e.what();
    return false;
  }
}

#define dec_error(dec) dec_errorx(aTHX_ (dec))
static SV *
dec_errorx(pTHX_ decoder *dec) {
  return newSVpvn(dec->error.data(), dec->error.size());
}

static std::vector<std::string>
dec_avail_formats() {
  std::vector<std::string> formats;
  for (auto f : BarcodeFormats::all()) {
    formats.emplace_back(ToString(f));
  }
  return formats;
}

inline ImageFormat
imager_to_ImageFormat(int channels) {
  switch (channels) {
  case 1:
    return ImageFormat::Lum;
  case 2:
    return ImageFormat::None;
  case 3:
    return ImageFormat::RGB;
  case 4:
    return ImageFormat::RGBX;
  default:
    return ImageFormat::None;
  }
}

static std::optional<Results>
dec_decode(decoder *dec, i_img *im) {
  // hackity hack
  ImageView image(im->idata, im->xsize, im->ysize, imager_to_ImageFormat(im->channels));

  if (image.format() == ImageFormat::None) {
    dec->error = "grayscale/alpha not supported";
    return {};
  }

  return ReadBarcodes(image, dec->hints);
}

#define res_text(res) res_textx(aTHX_ (res))
static SV *
res_textx(pTHX_ Result *res) {
  auto s = res->text();
  return newSVpvn(s.data(), s.size());
}

typedef decoder *Imager__zxing__Decoder;
typedef Result *Imager__zxing__Decoder__Result;

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder PREFIX=dec_

Imager::zxing::Decoder
dec_new(cls)
  C_ARGS:

void
dec_DESTROY(Imager::zxing::Decoder dec)

SV *
dec_formats(Imager::zxing::Decoder dec)

bool
dec_set_formats(Imager::zxing::Decoder dec, const char *formats)

void
dec_decode(Imager::zxing::Decoder dec, Imager im)
  PPCODE:
    auto results = dec_decode(dec, im);
    if (results) {
      EXTEND(SP, results->size());
      for (auto &&r : *results) {
        auto pr = new Result(r);
        SV *sv_r = newSV(0);
        sv_setref_pv(sv_r, "Imager::zxing::Decoder::Result", pr);
        PUSHs(sv_2mortal(sv_r));
      }
    }
    else {
      XSRETURN_EMPTY;
    }

SV *
dec_error(Imager::zxing::Decoder dec)

void
dec_avail_formats(cls)
  PPCODE:
    auto v = dec_avail_formats();
    EXTEND(SP, v.size());
    for (auto f : v) {
      PUSHs(sv_2mortal(newSVpvn(f.data(), f.size())));
    }

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder::Result PREFIX = res_

SV *
res_text(Imager::zxing::Decoder::Result res)

void
res_DESTROY(Imager::zxing::Decoder::Result res)
  PPCODE:
    delete res;

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;
