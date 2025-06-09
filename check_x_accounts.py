#!/usr/bin/env python3

'''
Go directly to an X account
'''

import sys
import webbrowser

root_url = 'https://x.com'

file = open('/Users/billp/.local/share/x_accounts.txt','r')

for i in file.readlines():
    response = str(input(i))
    if response == 'exit':
        sys.exit()

    if response == 'y':
        url = root_url + '/' + i
        webbrowser.open(url.strip())
        sys.exit()
