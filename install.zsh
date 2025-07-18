#!/usr/bin/env zsh

# Set up new project

# Validate arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: ${0:t} <project_name> [extra_packages]"
  exit 1
fi

NAME=$1
PACKAGES=("python-dotenv" ${(@s: :)2})  # Split extra packages
DB_DIR="$HOME/.local/share"
LOWERCASE_NAME=${(L)NAME}
UPPERCASE_NAME=${(U)NAME}
DB_PATH="$DB_DIR/$LOWERCASE_NAME/${LOWERCASE_NAME}.db"
VENV_NAME=$(echo "${LOWERCASE_NAME}" | sed "s/_/-/")-env

mkdir -p "$DB_DIR/$LOWERCASE_NAME" || exit 1
mkdir -p scripts || exit 1

GITIGNORE_CONTENT=".env
__pycache__/
/${VENV_NAME}/
"

CONFIG_CONTENT="#!/usr/bin/env python3

import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv('YOUTUBE_API_KEY')
DB_PATH = os.getenv('DB_PATH')
"

INITDB_CONTENT="#!/usr/bin/env python3

import config
import sqlite3

db = config.DB_PATH

conn = sqlite3.connect(db)
conn.execute('''
    CREATE TABLE IF NOT EXISTS youtube_videos (
        id INTEGER PRIMARY KEY,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        url TEXT NOT NULL
    )
''')
conn.close()
"

# Create files
print -l $PACKAGES > requirements.txt || exit 1
echo "DB_PATH=$DB_PATH" >> .env
echo -e $GITIGNORE_CONTENT > .gitignore
echo $CONFIG_CONTENT > config.py
echo $INITDB_CONTENT > init_db.py

~/Dev/scripts-git/mkvenv.sh "$VENV_NAME" || exit 1
./$VENV_NAME/bin/python -m pip install -r requirements.txt || exit 1

# Initialize database
chmod +x init_db.py
./init_db.py || exit 1
ln -sf "$DB_PATH" project.db

echo "Installation complete for $LOWERCASE_NAME!"
