#!/usr/bin/env zsh

# Set up new LLM company

# Validate arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: ${0:t} <project_name> [extra_packages]"
  exit 1
fi

NAME=$1
PACKAGES=("python-dotenv" "rich" ${(@s: :)2})  # Split extra packages
DB_DIR="$HOME/.local/share"
LOWERCASE_NAME=${(L)NAME}
UPPERCASE_NAME=${(U)NAME}
# Capitalize first letter only
CAPITALIZED_NAME="${(C)${NAME:0:1}}${NAME:1}"  
DB_PATH="$DB_DIR/$LOWERCASE_NAME/${LOWERCASE_NAME}_exchanges.db"
RESPONSE_FILE="${CAPITALIZED_NAME}_response.md"
VENV_NAME="${LOWERCASE_NAME}-env" # TODO replace _ with -

# Create directory structure first
mkdir -p "$DB_DIR/$LOWERCASE_NAME" || exit 1
mkdir -p scripts || exit 1

# Generate file contents
GITIGNORE_CONTENT=".env\n__pycache__/\n$VENV_NAME/\nprompt.txt\n$RESPONSE_FILE"

CONFIG_CONTENT="#!/usr/bin/env python3

import os
from dotenv import load_dotenv

load_dotenv()

${UPPERCASE_NAME}_API_KEY = os.getenv('${UPPERCASE_NAME}_API_KEY')
${UPPERCASE_NAME}_EXCHANGES_DB_PATH = os.getenv('${UPPERCASE_NAME}_EXCHANGES_DB_PATH')
"

INITDB_CONTENT="#!/usr/bin/env python3

import config
import sqlite3

db = config.${UPPERCASE_NAME}_EXCHANGES_DB_PATH

conn = sqlite3.connect(db)
conn.execute('''
    CREATE TABLE IF NOT EXISTS api_logs (
        id INTEGER PRIMARY KEY,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        prompt TEXT NOT NULL,
        response TEXT NOT NULL,
        model TEXT NOT NULL,
        system_message TEXT NOT NULL,
        thread_id INTEGER,
        parent_id INTEGER
    )
''')
conn.close()
"

# Create files
print -l $PACKAGES > requirements.txt || exit 1
echo "${UPPERCASE_NAME}_API_KEY=" > .env
echo "${UPPERCASE_NAME}_EXCHANGES_DB_PATH=$DB_PATH" >> .env
echo -e $GITIGNORE_CONTENT > .gitignore
echo $CONFIG_CONTENT > config.py
echo $INITDB_CONTENT > init_db.py
touch prompt.txt $RESPONSE_FILE

# Setup environment
python3 -m venv "$VENV_NAME" || exit 1
source "${VENV_NAME}/bin/activate"
pip install -r requirements.txt || exit 1
deactivate

# Initialize database
chmod +x init_db.py
./init_db.py || exit 1
ln -sf "$DB_PATH" project.db

# Copy dependencies if available
if [[ -f "../scripts-git/switch_cli.zsh" ]]; then
  cp ../scripts-git/switch_cli.zsh . 
  ./switch_cli.zsh
  mode blank # TODO does not work
fi

if [[ -f "../deepseek-git/scripts/submit_prompt.py" ]]; then
  cp "../deepseek-git/scripts/submit_prompt.py" scripts/
fi

echo "Installation complete for $CAPITALIZED_NAME!"
