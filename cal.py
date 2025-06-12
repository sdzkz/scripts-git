#!/usr/bin/env python3

import calendar
import sys
import curses
from datetime import datetime

def get_calendar_text(year, month, highlight_today=True):
    today = datetime.now()
    cal = calendar.TextCalendar(calendar.SUNDAY)
    month_days = cal.monthdayscalendar(year, month)
    
    grid_width = 7 * 4 + 8
    header = f"{calendar.month_name[month]} {year}"
    output = [header.center(grid_width)]
    output.append("┌────┬────┬────┬────┬────┬────┬────┐")
    output.append("│ Su │ Mo │ Tu │ We │ Th │ Fr │ Sa │")
    output.append("├────┼────┼────┼────┼────┼────┼────┤")
    
    for week in month_days:
        row = []
        for day in week:
            if day == 0:
                row.append("  ")
            else:
                if highlight_today and year == today.year and month == today.month and day == today.day:
                    row.append(f"\033[1;32m{day:>2}\033[0m")
                else:
                    row.append(f"{day:>2}")
        output.append("│" + "│".join(f" {day} " for day in row) + "│")
        output.append("├────┼────┼────┼────┼────┼────┼────┤")
    
    return "\n".join(output)

def print_calendar(year, month, highlight_today=True):
    print(get_calendar_text(year, month, highlight_today))

def view_calendar_interactive(start_year, start_month):
    year, month = start_year, start_month
    
    try:
        # Initialize curses
        stdscr = curses.initscr()
        curses.noecho()
        curses.cbreak()
        stdscr.keypad(True)
        curses.curs_set(0)
        
        while True:
            stdscr.clear()
            cal_text = get_calendar_text(year, month, False)
            stdscr.addstr(0, 0, cal_text)
            stdscr.refresh()
            
            key = stdscr.getch()
            if key == curses.KEY_DOWN:
                month += 1
                if month > 12:
                    month = 1
                    year += 1
            elif key == curses.KEY_UP:
                month -= 1
                if month < 1:
                    month = 12
                    year -= 1
            elif key == 10:  # Enter key
                break
    finally:
        # Clean up curses
        curses.nocbreak()
        stdscr.keypad(False)
        curses.echo()
        curses.endwin()
    
    return year, month

if __name__ == "__main__":
    today = datetime.now()
    year, month = today.year, today.month
    
    if "--next" in sys.argv:
        month += 1
        if month > 12:
            month = 1
            year += 1
    
    if "--view" in sys.argv:
        final_year, final_month = view_calendar_interactive(year, month)
        print_calendar(final_year, final_month)
    else:
        print_calendar(year, month)
