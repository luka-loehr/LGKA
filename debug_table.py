#!/usr/bin/env python3
"""Debug table extraction"""
import pdfplumber

pdf_path = 'Stundenpläne KL 5-10 2025-2026.pdf'

with pdfplumber.open(pdf_path) as pdf:
    # Get first page
    page = pdf.pages[0]
    
    print('=== PAGE TEXT ===')
    print(page.extract_text()[:1000])
    
    print('\n=== TABLES ===')
    tables = page.extract_tables()
    print(f'Number of tables: {len(tables)}')
    
    if tables:
        table = tables[0]
        print(f'\nTable rows: {len(table)}')
        print(f'First row: {table[0] if table else "None"}')
        print('\nFirst 10 rows:')
        for i, row in enumerate(table[:10]):
            print(f'  Row {i}: {row}')
