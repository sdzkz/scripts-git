#!/Users/billp/Dev/scripts-git/render_md-env/bin/python3

from rich.console import Console
from rich.markdown import Markdown
import sys

def render_markdown(content):
    """Render markdown content to the console"""
    try:
        markdown = Markdown(content)
        Console(file=sys.stdout).print(markdown)
    except Exception as e:
        print(f"An error occurred: {e}")

def render_markdown_file(filename):
    """Render markdown file to the console"""
    try:
        with open(filename, 'r') as md_file:
            render_markdown(md_file.read())
    except FileNotFoundError:
        print(f"Error: {filename} does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python render-md.py <filename>")
        sys.exit(1)
    render_markdown_file(sys.argv[1])

