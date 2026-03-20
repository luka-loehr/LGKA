#!/usr/bin/env python3
"""Extract all class schedules from PDF and save as JSON"""
import pdfplumber
import json
import re
import os

def is_class_name(text):
    """Check if text is a class name like '5a', '10b'"""
    return bool(re.match(r'^(\d+[a-e])$', text.strip()))

def extract_lesson(cell_text):
    """Extract subject, teacher, room from cell text"""
    if not cell_text or cell_text.strip() == '':
        return None
    
    lines = [l.strip() for l in cell_text.split('\n') if l.strip()]
    if len(lines) < 1:
        return None
    
    # Skip cells that are just footers
    if any(marker in lines[0] for marker in ['HJ', 'Periode', 'SJ', '20', 'Februar']):
        return None
    
    # First line is subject
    subject = lines[0]
    
    # Skip if subject looks like a footer marker
    if re.match(r'^\d+\.\s*HJ', subject):
        return None
    
    # Try to find teacher (usually 2-4 letters)
    teacher = ''
    room = ''
    
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue
        # Skip footer markers
        if any(marker in line for marker in ['HJ', 'Periode', 'SJ', '2.', 'Februar']):
            continue
        # Teacher codes are typically 2-5 letters starting with uppercase
        if re.match(r'^[A-Z][a-z]{1,4}(\s+[A-Z][a-z]{1,4})*$', line):
            teacher = line
        # Rooms are numbers or room codes like BKOG, EBad1
        elif re.match(r'^(\d+|[A-Z]+\d*|EBad\d|WB\d|MUSIK)$', line):
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
    
    # Find class name - look for timestamp then class
    class_name = None
    class_teachers = []
    
    for i, line in enumerate(lines):
        # Look for timestamp pattern
        if re.match(r'\d{1,2}\.\d{1,2}\.\d{4}', line) and ':' in line:
            if i + 1 < len(lines):
                possible_class = lines[i + 1].strip()
                if is_class_name(possible_class):
                    class_name = possible_class
                    # Get teachers from next line if it contains /
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
    
    # Parse table rows - skip header row
    for row_idx in range(1, len(table)):
        row = table[row_idx]
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
        days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag']
        for day_idx in range(5):
            col_idx = day_idx + 1
            if col_idx >= len(row):
                continue
            
            cell = row[col_idx]
            if not cell or not str(cell).strip():
                continue
            
            lesson_data = extract_lesson(str(cell))
            if lesson_data and lesson_data['subject'] and not lesson_data['subject'].startswith('2.'):
                lessons.append({
                    'period': period,
                    'dayIndex': day_idx,
                    'dayName': days[day_idx],
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
    
    # Create output directory if needed
    os.makedirs('assets/data', exist_ok=True)
    
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
    
    # Show sample for 5a
    if '5a' in all_schedules:
        print('\n\nSample: 5a schedule (first 10 lessons)')
        for lesson in all_schedules['5a']['lessons'][:10]:
            print(f"  {lesson['dayName']} {lesson['period']}: {lesson['subject']} - {lesson['teacher']} - {lesson['room']}")

if __name__ == '__main__':
    main()
