#!/usr/bin/env python3
"""Debug word positions"""
import pdfplumber

pdf_path = "Stundenpläne KL 5-10 2025-2026.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    words = page.extract_words()
    
    print("=== ALL WORDS WITH POSITIONS ===")
    for i, word in enumerate(words[:80]):
        print(f"{i:2d}: '{word['text']:15}' x={word['x0']:6.1f} y={word['top']:6.1f}")
    
    print("\n=== LOOKING FOR CLASS NAME ===")
    for i, word in enumerate(words):
        text = word['text'].strip()
        if text == '5a':
            print(f"Found '5a' at index {i}, x={word['x0']}, y={word['top']}")
            # Show context
            start = max(0, i-3)
            end = min(len(words), i+5)
            print("Context:")
            for j in range(start, end):
                print(f"  {j}: '{words[j]['text']}'")
            break
