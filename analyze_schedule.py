#!/usr/bin/env python3
"""Analyze schedule PDF structure using pdfplumber"""
import pdfplumber
import json
import sys

def analyze_schedule(pdf_path):
    with pdfplumber.open(pdf_path) as pdf:
        print(f"Total pages: {len(pdf.pages)}")
        
        # Analyze first page (class 5a)
        page = pdf.pages[0]
        
        print("\n=== PAGE 1 TEXT ===")
        text = page.extract_text()
        print(text[:1500])
        
        print("\n=== TABLE ANALYSIS ===")
        # Try to extract as table
        tables = page.extract_tables()
        print(f"Found {len(tables)} tables")
        
        if tables:
            table = tables[0]
            print(f"Table rows: {len(table)}")
            print(f"Table cols: {len(table[0]) if table else 0}")
            print("\nFirst 15 rows:")
            for i, row in enumerate(table[:15]):
                print(f"Row {i}: {row}")
        
        # Also try to get words with positions
        print("\n=== WORDS WITH POSITIONS (first 100) ===")
        words = page.extract_words()
        for word in words[:100]:
            print(f"  {word['text']:15} x:{word['x0']:6.1f} y:{word['top']:6.1f}")
        
        return True

def extract_all_schedules(pdf_path):
    """Extract all class schedules from PDF"""
    schedules = {}
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            print(f"\n=== Processing page {page_num + 1} ===")
            
            text = page.extract_text()
            lines = [l.strip() for l in text.split('\n') if l.strip()]
            
            # Find class name (usually after timestamp)
            class_name = None
            for i, line in enumerate(lines):
                if '.' in line and ':' in line:  # Timestamp line like "8.1.2026  13:47"
                    if i + 1 < len(lines):
                        possible_class = lines[i + 1]
                        if len(possible_class) <= 4 and possible_class[0].isdigit():
                            class_name = possible_class
                            break
            
            if not class_name:
                print(f"  Could not find class name on page {page_num + 1}")
                continue
                
            print(f"  Class: {class_name}")
            
            # Extract table
            tables = page.extract_tables()
            if not tables:
                print(f"  No table found on page {page_num + 1}")
                continue
            
            table = tables[0]
            print(f"  Table: {len(table)} rows x {len(table[0]) if table else 0} cols")
            
            # Parse the schedule grid
            schedule = parse_schedule_table(table, class_name)
            schedules[class_name] = schedule
    
    return schedules

def parse_schedule_table(table, class_name):
    """Parse schedule table into structured format"""
    lessons = []
    
    # Days are columns 1-5 (column 0 is period number)
    days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag']
    
    for row_idx, row in enumerate(table):
        if not row or len(row) < 6:
            continue
        
        # First column should be period number
        period_str = str(row[0]).strip() if row[0] else ''
        if not period_str.isdigit():
            continue
        
        period = int(period_str)
        
        # For each day column
        for day_idx in range(5):
            col_idx = day_idx + 1
            if col_idx >= len(row):
                continue
            
            cell_content = row[col_idx]
            if not cell_content:
                continue
            
            # Parse cell content - should have subject, teacher, room
            cell_lines = [l.strip() for l in str(cell_content).split('\n') if l.strip()]
            
            if len(cell_lines) >= 3:
                subject = cell_lines[0]
                teacher = cell_lines[1]
                room = cell_lines[2]
                
                # Skip empty cells or breaks
                if subject and subject not in ['', '.', '-']:
                    lessons.append({
                        'period': period,
                        'dayIndex': day_idx,
                        'dayName': days[day_idx],
                        'subject': subject,
                        'teacher': teacher,
                        'room': room
                    })
    
    return {
        'className': class_name,
        'lessons': lessons,
        'totalLessons': len(lessons)
    }

if __name__ == '__main__':
    pdf_path = "Stundenpläne KL 5-10 2025-2026.pdf"
    
    print("=== ANALYZING PDF STRUCTURE ===")
    analyze_schedule(pdf_path)
    
    print("\n\n=== EXTRACTING ALL SCHEDULES ===")
    schedules = extract_all_schedules(pdf_path)
    
    print(f"\n\n=== SUMMARY ===")
    print(f"Extracted {len(schedules)} class schedules:")
    for class_name in sorted(schedules.keys()):
        schedule = schedules[class_name]
        print(f"  {class_name}: {schedule['totalLessons']} lessons")
    
    # Save to JSON
    output_path = "schedule_data.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(schedules, f, indent=2, ensure_ascii=False)
    
    print(f"\nSaved to: {output_path}")
