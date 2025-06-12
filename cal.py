#!/usr/bin/env python3

import calendar
import sys
from datetime import datetime

def print_calendar(year, month, highlight_today=True):
    today = datetime.now()
    cal = calendar.TextCalendar(calendar.SUNDAY)
    month_days = cal.monthdayscalendar(year, month)
    
    # Calculate grid width (7 columns * 4 chars each + 8 borders)
    grid_width = 7 * 4 + 8
    header = f"{calendar.month_name[month]} {year}"
    print(header.center(grid_width))
    
    print("┌────┬────┬────┬────┬────┬────┬────┐")
    print("│ Su │ Mo │ Tu │ We │ Th │ Fr │ Sa │")
    print("├────┼────┼────┼────┼────┼────┼────┤")
    
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
        print("│" + "│".join(f" {day} " for day in row) + "│")
        print("├────┼────┼────┼────┼────┼────┼────┤")

if __name__ == "__main__":
    today = datetime.now()
    year, month = today.year, today.month
    
    if "--next" in sys.argv:
        month += 1
        if month > 12:
            month = 1
            year += 1
    
    print_calendar(year, month)
