#!/usr/bin/env python3
"""Improved schedule PDF parser using word positions"""
import pdfplumber
import json
from collections import defaultdict

def extract_schedule_from_page(page):
    """Extract schedule by analyzing word positions"""
    words = page.extract_words()
    
    # Find class name
    class_name = None
    class_teachers = []
    
    for i, word in enumerate(words):
        text = word['text'].strip()
        # Class name pattern: "5a", "10b", etc.
        if len(text) <= 4 and text and text[0].isdigit() and len([c for c in text if c.isalpha()]) <= 2:
            if i > 0:
                prev_word = words[i-1]['text']
                if '.' in prev_word and ':' in prev_word:  # After timestamp
                    class_name = text
                    # Next word might be teachers
                    if i + 1 < len(words):
                        next_text = words[i+1]['text']
                        if '/' in next_text:
                            class_teachers = next_text.split('/')
                    break
    
    if not class_name:
        return None
    
    # Find day columns
    day_x_positions = {}
    day_names = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag']
    
    for word in words:
        if word['text'] in day_names:
            day_x_positions[word['text']] = word['x0']
    
    # Sort days by x position
    days_sorted = sorted(day_x_positions.items(), key=lambda x: x[1])
    day_order = [d[0] for d in days_sorted]
    
    # Find period rows
    period_y_positions = {}
    for word in words:
        text = word['text'].strip()
        if text.isdigit() and 1 <= int(text) <= 11:
            period_y_positions[int(text)] = word['top']
    
    # Sort periods by y position
    periods_sorted = sorted(period_y_positions.items(), key=lambda x: x[1])
    
    # Now collect all content words (not headers)
    content_words = []
    for word in words:
        text = word['text'].strip()
        if text in day_names or text.isdigit() and int(text) <= 11:
            continue
        if '.' in text and ':' in text:  # Timestamp
            continue
        if text in ['Lessing-Gymnasium', 'Karlsruhe', 'SJ', 'Untis']:
            continue
        if text.startswith('HJ') or '20' in text:
            continue
        content_words.append(word)
    
    # Group words by period (y-position)
    lessons = []
    
    for period_num, period_y in periods_sorted:
        # Find words in this row (within vertical range)
        row_words = [w for w in content_words 
                     if abs(w['top'] - period_y) < 25 and w['top'] > 60]
        
        # Group by day column (x-position)
        for day_idx, (day_name, day_x) in enumerate(days_sorted):
            # Find words in this day column
            col_words = [w for w in row_words 
                        if abs(w['x0'] - day_x) < 100 and w['x0'] > day_x - 20]
            
            if col_words:
                # Sort by y position within cell
                col_words.sort(key=lambda w: w['top'])
                lines = [w['text'] for w in col_words]
                
                if lines:
                    # Parse subject, teacher, room
                    subject = lines[0] if len(lines) > 0 else ''
                    teacher = lines[1] if len(lines) > 1 else ''
                    room = lines[2] if len(lines) > 2 else ''
                    
                    # Skip empty or header cells
                    if subject and subject not in ['', '.', 'HJ', 'Februar'] and not subject.startswith('20'):
                        lessons.append({
                            'period': period_num,
                            'dayIndex': day_idx,
                            'dayName': day_name,
                            'subject': subject,
                            'teacher': teacher,
                            'room': room
                        })
    
    return {
        'className': class_name,
        'classTeachers': class_teachers,
        'lessons': lessons
    }

def extract_all_schedules_v2(pdf_path):
    """Extract all class schedules using position-based parsing"""
    schedules = {}
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"Processing {len(pdf.pages)} pages...")
        
        for page_num, page in enumerate(pdf.pages):
            print(f"  Page {page_num + 1}...", end=' ')
            
            schedule = extract_schedule_from_page(page)
            
            if schedule and schedule['lessons']:
                schedules[schedule['className']] = schedule
                print(f"Found {schedule['className']} with {len(schedule['lessons'])} lessons")
            else:
                print("No valid schedule found")
    
    return schedules

if __name__ == '__main__':
    pdf_path = "Stundenpläne KL 5-10 2025-2026.pdf"
    
    print("=== EXTRACTING SCHEDULES (V2) ===")
    schedules = extract_all_schedules_v2(pdf_path)
    
    print(f"\n=== SUMMARY ===")
    print(f"Extracted {len(schedules)} class schedules:")
    for class_name in sorted(schedules.keys()):
        schedule = schedules[class_name]
        print(f"  {class_name}: {len(schedule['lessons'])} lessons")
    
    # Save to JSON
    output_path = "schedule_data_v2.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(schedules, f, indent=2, ensure_ascii=False)
    
    print(f"\nSaved to: {output_path}")
    
    # Show sample for class 5a
    if '5a' in schedules:
        print("\n=== SAMPLE: Class 5a ===")
        print(json.dumps(schedules['5a'], indent=2, ensure_ascii=False))
