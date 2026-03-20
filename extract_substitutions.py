#!/usr/bin/env python3
"""Extract substitution data from PDFs and save as JSON"""
import pdfplumber
import json
import re
from datetime import datetime

def parse_substitution_pdf(pdf_path, is_today=True):
    """Parse a substitution PDF (heute or morgen)"""
    substitutions = []
    
    with pdfplumber.open(pdf_path) as pdf:
        text = pdf.pages[0].extract_text()
    
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    
    # Extract metadata
    date = ''
    weekday = ''
    last_updated = ''
    absent_teachers = []
    
    for i, line in enumerate(lines):
        # Find date/weekday from header
        if 'Lessing-Klassen' in line:
            match = re.search(r'(\d{1,2}\.\d{1,2})\.\s*/\s*(\w+)', line)
            if match:
                date = match.group(1)
                weekday = match.group(2)
        
        # Find last updated
        if re.search(r'\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2}', line):
            last_updated = line.strip()
        
        # Find absent teachers
        if 'Abwesende Lehrer:' in line:
            teachers_text = line.replace('Abwesende Lehrer:', '').strip()
            absent_teachers = [t.strip() for t in teachers_text.split(',') if t.strip()]
    
    # Find table data - look for type patterns
    type_patterns = {
        'Betreuung': 'supervision',
        'Entfall': 'cancellation',
        'Verlegung': 'relocation',
        'Tausch': 'exchange',
        'Raum-Vtr.': 'roomChange',
        'Raumvtr.': 'roomChange',
        'Sonderein': 'specialUnit',
        'Lehrprobe': 'teacherObservation',
        'Unterricht': 'substitution',
        'Vertretung': 'substitution',
    }
    
    # Parse entries - look for lines starting with types
    current_type = None
    
    for line in lines:
        # Check if line starts with a type
        for type_name, type_key in type_patterns.items():
            if line.startswith(type_name):
                current_type = type_key
                # Parse the rest of the line
                rest = line[len(type_name):].strip()
                
                # Try to parse: Period Class Teacher Subject Room [OrigSubject] [OrigTeacher] [OrigRoom] [Text]
                parts = rest.split()
                if len(parts) >= 4:
                    period = parts[0]
                    class_name = parts[1]
                    teacher = parts[2]
                    subject = parts[3]
                    room = parts[4] if len(parts) > 4 else ''
                    
                    # Determine if cancellation
                    is_cancellation = type_key == 'cancellation'
                    
                    # For cancellations, the original info is in parentheses later
                    orig_teacher = ''
                    orig_subject = ''
                    orig_room = ''
                    text = ''
                    
                    if len(parts) > 5:
                        # Check for original info (not ---)
                        idx = 5
                        if idx < len(parts) and parts[idx] != '---':
                            orig_subject = parts[idx]
                            idx += 1
                        if idx < len(parts) and parts[idx] != '---':
                            orig_teacher = parts[idx]
                            idx += 1
                        if idx < len(parts) and parts[idx] != '---':
                            orig_room = parts[idx]
                            idx += 1
                        
                        # Rest is text
                        if idx < len(parts):
                            text = ' '.join(parts[idx:])
                    
                    substitutions.append({
                        'type': type_key,
                        'period': period,
                        'className': class_name,
                        'subject': subject,
                        'teacher': teacher,
                        'room': room,
                        'originalTeacher': orig_teacher,
                        'originalSubject': orig_subject,
                        'originalRoom': orig_room,
                        'isCancellation': is_cancellation,
                        'text': text,
                    })
                break
    
    return {
        'date': date,
        'weekday': weekday,
        'lastUpdated': last_updated,
        'absentTeachers': absent_teachers,
        'substitutions': substitutions,
        'isToday': is_today,
    }

def main():
    # Parse both PDFs
    today_data = parse_substitution_pdf('V Schueler Heute.pdf', is_today=True)
    tomorrow_data = parse_substitution_pdf('V Schueler Morgen.pdf', is_today=False)
    
    output = {
        'today': today_data,
        'tomorrow': tomorrow_data,
        'exportedAt': datetime.now().isoformat(),
    }
    
    # Save to JSON
    output_path = 'assets/data/substitutions.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f'Saved substitution data to {output_path}')
    print(f'\nToday ({today_data["weekday"]}, {today_data["date"]}):')
    print(f'  {len(today_data["substitutions"])} substitutions')
    print(f'  Absent teachers: {len(today_data["absentTeachers"])}')
    
    print(f'\nTomorrow ({tomorrow_data["weekday"]}, {tomorrow_data["date"]}):')
    print(f'  {len(tomorrow_data["substitutions"])} substitutions')
    print(f'  Absent teachers: {len(tomorrow_data["absentTeachers"])}')
    
    # Show sample substitutions
    if today_data['substitutions']:
        print('\nSample substitutions (today):')
        for sub in today_data['substitutions'][:5]:
            print(f"  {sub['className']} {sub['period']}: {sub['type']} - {sub['subject']}")

if __name__ == '__main__':
    main()
