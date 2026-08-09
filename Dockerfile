FROM python:3.13-slim

WORKDIR /app

# Install Flex, Bison and GCC
RUN apt-get update && apt-get install -y \
    flex \
    bison \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Build MiniC compiler
WORKDIR /app/compiler_engine

RUN flex lexer.l && \
    bison -d parser.y && \
    gcc lex.yy.c parser.tab.c -o compiler_engine

# Back to Django project
WORKDIR /app

# Collect static files
RUN python manage.py collectstatic --no-input

# Database migration
RUN python manage.py migrate

# Start Django
CMD ["gunicorn", "online_compiler.wsgi:application", "--bind", "0.0.0.0:10000"]