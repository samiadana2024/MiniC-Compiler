#!/usr/bin/env bash

set -o errexit

echo "Installing Python dependencies..."
pip install -r requirements.txt

echo "Building MiniC compiler..."

cd compiler_engine

flex lexer.l
bison -d parser.y
gcc lex.yy.c parser.tab.c -o compiler_engine

echo "Compiler engine built successfully."

cd ..

python manage.py collectstatic --no-input
python manage.py migrate