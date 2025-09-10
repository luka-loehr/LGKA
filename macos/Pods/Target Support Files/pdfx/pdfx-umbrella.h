#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "messages.h"
#import "pdfx.h"
#import "PdfxPlugin.h"

FOUNDATION_EXPORT double pdfxVersionNumber;
FOUNDATION_EXPORT const unsigned char pdfxVersionString[];

