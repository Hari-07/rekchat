# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python FastAPI backend service that acts as a security-focused proxy for code execution. It receives data files and queries, validates them for security issues, and executes safe Python code against uploaded CSV data.

## Development Commands

- **Run development server**: `just run` (starts FastAPI dev server on port 8001)
- **Alternative**: `fastapi dev main.py --port 8001`

## Architecture

### Core Components

- **FastAPI Application** (`main.py`): Single-file application with two main endpoints
- **Security Layer**: Built-in validation to prevent unsafe code execution
- **Data Processing**: CSV file upload and pandas-based data analysis

### Key Endpoints

- `POST /upload-file`: Accepts CSV files, validates format, stores metadata
- `POST /submit-query`: Receives queries, validates code safety, executes against data

### Security Model

The application implements a defensive security approach:

- **Pattern Detection**: Blocks code containing dangerous imports/operations (os, sys, subprocess, etc.)
- **Retry Mechanism**: Automatically requests safer code when security issues are detected
- **Restricted Execution**: Only allows pandas, numpy, math, and datetime operations
- **Code Isolation**: Uses exec() with controlled namespace

### Data Flow

1. CSV files uploaded via `/upload-file` → stored locally with metadata
2. Query submitted to `/submit-query` → forwarded to main backend (port 8000)
3. LLM response parsed for `<python_code>` blocks
4. Security validation performed
5. Safe code executed against uploaded data
6. Results returned as JSON

### Dependencies

The codebase uses:
- FastAPI for web framework
- pandas for data processing  
- httpx for async HTTP requests
- Standard library modules (re, json, pathlib, etc.)

No explicit requirements.txt or pyproject.toml - dependencies should be installed manually.