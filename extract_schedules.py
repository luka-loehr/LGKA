#!/usr/bin/env python3
"""Extract all class schedules from PDF and save as JSON"""
import pdfplumber
import json
import re

def is_class_name(text):
    """Check if text is a class name like '5a', '10b'"""
    return bool(re.match(r'^\d+[a-e]$', text.strip()))

def extract_lesson(cell_text):
    """Extract subject, teacher, room from cell text"""
    if not cell_text or cell_text.strip() == '':
        return None
    
    lines = [l.strip() for l in cell_text.split('\n') if l.strip()]
    if len(lines) < 1:
        return None
    
    # First line is subject
    subject = lines[0]
    
    # Try to find teacher (usually 2-4 letters)
    teacher = ''
    room = ''
    
    for line in lines[1:]:
        # Teacher codes are typically 2-4 uppercase letters
        if re.match(r'^[A-Z][a-z]{1,4}$', line):
            teacher = line
        # Rooms are numbers or room codes
        elif re.match(r'^(\d+|[A-Z]+\d*)$', line):
            room = line
    
    return {
        'subject': subject,
        'teacher': teacher,
        'room': room
    }

def parse_page(page):
    """Parse a single page and extract schedule"""
    text = page.extract_text()
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    
    # Find class name
    class_name = None
    class_teachers = []
    
    for i, line in enumerate(lines):
        # Look for timestamp, next line is class
        if re.match(r'\d{1,2}\.\d{1,2}\.\d{4}', line) and ':' in line:
            if i + 1 < len(lines):
                possible_class = lines[i + 1]
                if is_class_name(possible_class):
                    class_name = possible_class
                    # Get teachers
                    if i + 2 < len(lines) and '/' in lines[i + 2]:
                        class_teachers = [t.strip() for t in lines[i + 2].split('/')]
                    break
    
    if not class_name:
        return None
    
    # Extract table using pdfplumber
    tables = page.extract_tables()
    if not tables:
        return None
    
    table = tables[0]
    lessons = []
    
    # Parse table rows
    for row_idx, row in enumerate(table):
        if not row or len(row) < 6:
            continue
        
        # First column should be period
        period_str = str(row[0]).strip() if row[0] else ''
        if not period_str.isdigit():
            continue
        
        period = int(period_str)
        if period < 1 or period > 11:
            continue
        
        # Parse each day column (columns 1-5)
        for day_idx in range(5):
            col_idx = day_idx + 1
            if col_idx >= len(row):
                continue
            
            cell = row[col_idx]
            if not cell:
                continue
            
            lesson_data = extract_lesson(cell)
            if lesson_data and lesson_data['subject']:
                lessons.append({
                    'period': period,
                    'dayIndex': day_idx,
                    'subject': lesson_data['subject'],
                    'teacher': lesson_data['teacher'],
                    'room': lesson_data['room']
                })
    
    return {
        'className': class_name,
        'classTeachers': class_teachers,
        'lessons': lessons
    }

def main():
    pdf_path = 'Stundenpläne KL 5-10 2025-2026.pdf'
    
    print(f'Processing {pdf_path}...')
    
    all_schedules = {}
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f'Total pages: {len(pdf.pages)}')
        
        for page_num, page in enumerate(pdf.pages):
            print(f'\nProcessing page {page_num + 1}...', end=' ')
            
            schedule = parse_page(page)
            if schedule:
                all_schedules[schedule['className']] = schedule
                print(f"Found {schedule['className']} with {len(schedule['lessons'])} lessons")
            else:
                print('No valid schedule found')
    
    # Save to JSON
    output = {
        'schoolYear': '2025-2026',
        'lastUpdated': '2026-02-11T00:00:00Z',
        'classSchedules': all_schedules
    }
    
    output_path = 'assets/data/schedule_data.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f'\n\nSaved {len(all_schedules)} class schedules to {output_path}')
    
    # Print summary
    print('\nSummary:')
    for class_name in sorted(all_schedules.keys()):
        schedule = all_schedules[class_name]
        print(f"  {class_name}: {len(schedule['lessons'])} lessons")

if __name__ == '__main__':
    main()
