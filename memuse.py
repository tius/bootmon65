#   memuse.py
#
#   display memory usage from ld65 map file
#
#   usage: memuse.py <mapfile> [-v]

import sys
import re
import argparse

def read_sections(map_file):
    with open(map_file, 'r') as file:
        lines = file.readlines()

    re_title = re.compile(r'^([A-Z][\w ]+):', re.IGNORECASE)

    title = None
    sections = {}

    for line in lines:
        m = re_title.match(line)
        if m:
            title = m.group(1).lower()
            sections[title] = []
            continue
        if title:
            sections[title].append(line)
            continue
    return sections

def print_segments( segment_list ):
    re_section = re.compile(r'^(\w+)\s+([0-9A-Z]+)\s+([0-9A-Z]+)\s+([0-9A-Z]+)\s+([0-9A-Z]+)')
   
    segments = []

    print()
    for line in segment_list:
        m = re_section.match(line)
        if m:
            name = m.group(1)
            start = int( m.group(2), 16 )
            end = int( m.group(3), 16 )
            size = int( m.group(4), 16 )
            if (size == 0):
                continue
            segments.append(name )
            print( f"{name:10} {start:04X}   {size:04X} {size:8}" )

    return segments

def print_modules( segments, modules_list ):
    # print("Modules:")

    re_obj = re.compile(r'(\w+)\.o')
    re_section = re.compile(r'^\s+(\w+).*Size=([0-9A-Z]+)')
    modules = []
    sizes = {}

    print()
    for line in modules_list:
        m = re_obj.search(line)
        if m:
            obj_name = m.group(1)
            modules.append(obj_name)
            sizes[obj_name] = {}
            continue

        m = re_section.match(line)
        if m:
            section = m.group(1)
            size = int( m.group(2), 16 )
            if (size == 0):
                continue
            sizes[obj_name][section] = size
            continue

    modules.sort()
    for segment in segments:
        print(segment)
        for module in modules:
            size = sizes[module].get(segment, 0)
            if size > 0:
                print(f"  {module:24}{size:5}")                
        print()

def main(): 
    parser = argparse.ArgumentParser()
    parser.add_argument("mapfile", help="ld65 map file")
    parser.add_argument("-v", "--verbose", help="verbose output", action="store_true")
    args = parser.parse_args()

    sections = read_sections( args.mapfile )
    segments = print_segments( sections['segment list']  )

    if args.verbose:
        print_modules( segments, sections['modules list'] )

if __name__ == "__main__":
    main()

