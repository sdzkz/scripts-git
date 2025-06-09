#!/usr/bin/env python3

'''
Look though sqlite db a row at a time.
'''

import sqlite3
import curses
import json
import sys
import base64
import os
import glob

def find_first_db():
    """Find first .db file in current directory"""
    db_files = glob.glob("*.db")
    if not db_files:
        return None
    return sorted(db_files)[0]

def get_first_table(db_path):
    """Get first table name alphabetically from database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name LIMIT 1")
    table = cursor.fetchone()
    conn.close()
    return table[0] if table else None

def main():
    # Handle arguments
    if len(sys.argv) == 1:  # No arguments
        db_path = find_first_db()
        if not db_path:
            print("No .db files found in current directory")
            sys.exit(1)
            
        table = get_first_table(db_path)
        if not table:
            print(f"No tables found in database: {db_path}")
            sys.exit(1)
            
        query = f"SELECT * FROM {table}"
        print(f"Using database: {db_path}\nUsing table: {table}")
        
    elif len(sys.argv) == 2:  # Only database provided
        db_path = sys.argv[1]
        table = get_first_table(db_path)
        if not table:
            print(f"No tables found in database: {db_path}")
            sys.exit(1)
            
        query = f"SELECT * FROM {table}"
        print(f"Using table: {table}")
        
    else:  # Both database and query provided
        db_path = sys.argv[1]
        query = sys.argv[2]

    # Connect to database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    columns = [col[0] for col in cursor.description] if cursor.description else []
    conn.close()

    if not rows:
        print("No rows found")
        return

    def display_row(stdscr, row_idx):
        stdscr.clear()
        stdscr.addstr(0, 0, f"Row {row_idx+1}/{len(rows)} (Press ↓ for next, ENTER to exit)")
        
        for i, (col, val) in enumerate(zip(columns, rows[row_idx])):
            display_val = ""
            if val is None:
                display_val = "NULL"
            elif isinstance(val, bytes):
                display_val = f"<BINARY: {len(val)} bytes>"
            else:
                display_val = str(val)
            
            # Truncate long values
            max_width = curses.COLS - len(col) - 3
            if len(display_val) > max_width:
                display_val = display_val[:max_width-3] + "..."
                
            stdscr.addstr(i+2, 0, f"{col}: {display_val}")
        stdscr.refresh()

    # Run UI and get last viewed index
    last_row_index = curses.wrapper(
        lambda stdscr: run_ui(stdscr, rows, display_row)
    )

    # Output last viewed row as JSON
    row_dict = {}
    for col, val in zip(columns, rows[last_row_index]):
        if isinstance(val, bytes):
            val = base64.b64encode(val).decode('ascii')
        row_dict[col] = val
    print(json.dumps(row_dict))

def run_ui(stdscr, rows, display_callback):
    """Run the UI and return the last viewed index"""
    stdscr.keypad(True)
    curses.curs_set(0)
    current_idx = 0

    while True:
        display_callback(stdscr, current_idx)
        key = stdscr.getch()

        if key == curses.KEY_DOWN:
            if current_idx < len(rows) - 1:
                current_idx += 1
            else:
                break
        elif key in (10, 13):  # Enter key
            break
    
    return current_idx  # Return the last viewed index

if __name__ == "__main__":
    main()
