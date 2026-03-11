#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <search_string>"
    exit 1
fi

SEARCH="$1"
LLMS="claude deepseek gemini grok mistral moonshot open-ai qwen"
DIR="$(cd "$(dirname "$0")" && pwd)"

python3 -c "
import sqlite3, re, sys, os
from datetime import datetime

search = sys.argv[1].lower()
llms = sys.argv[2].split()
base = sys.argv[3]
results = []

for llm in llms:
    db_path = os.path.join(base, llm, 'project.db')
    if not os.path.isfile(db_path):
        continue
    db = sqlite3.connect(db_path)
    rows = db.execute('''
        SELECT id, created_at, prompt, thread_id
        FROM api_logs
        WHERE (thread_id IS NULL OR id = (SELECT MIN(id) FROM api_logs a2 WHERE a2.thread_id = api_logs.thread_id))
    ''').fetchall()
    for id, ts, prompt, tid in rows:
        stripped = re.sub(r'\x60\x60\x60.*?\x60\x60\x60', '', prompt, flags=re.DOTALL)
        if search in stripped.lower():
            clean = stripped.replace('\n', ' ').replace('\r', ' ')[:100]
            results.append((ts or '', id, llm, clean))
    db.close()

results.sort(key=lambda r: r[0])

max_id = max((len(str(r[1])) for r in results), default=1)
max_llm = max((len(r[2]) for r in results), default=1)

for ts, id, llm, clean in results:
    try:
        dt = datetime.strptime(ts[:10], '%Y-%m-%d')
        date = dt.strftime('%b %d')
    except:
        date = '      '
    print(f'\033[36m{date}\033[0m {str(id).ljust(max_id)} \033[36m{llm.ljust(max_llm)}\033[0m {clean}')
" "$SEARCH" "$LLMS" "$DIR"
