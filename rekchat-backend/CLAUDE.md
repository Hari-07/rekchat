# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This is a Python FastAPI backend with minimal setup. The project doesn't use a standard package manager configuration file, so dependencies need to be managed manually.

**Required dependencies:**
- `fastapi` - Web framework
- `anthropic` - Claude API client
- `pydantic` - Data validation (used by FastAPI)
- `uvicorn` - ASGI server for running FastAPI

**To run the server:**
```bash
uvicorn src.main:app --reload
```

**To install dependencies:**
```bash
pip install fastapi anthropic uvicorn pydantic
```

## Architecture Overview

This is a simple data analysis backend that generates Python code for CSV analysis using Claude AI:

**Core Components:**
- `src/main.py` - FastAPI application with single `/submit-query` endpoint
- `src/utils/llm.py` - Claude API integration using Anthropic client
- `src/utils/prompt.py` - Prompt engineering for CSV analysis tasks

**Request Flow:**
1. Client sends POST to `/submit-query` with query and CSV file metadata (names + column headers)
2. File metadata is formatted into descriptive text (`user_files_data_formatted`)
3. Query and metadata are inserted into analysis prompt template (`filled_in_prompt`)
4. Prompt is sent to Claude 3.5 Haiku via Anthropic API (`submit_query`)
5. Claude generates Python pandas code for CSV analysis
6. Generated code is returned to client

**Key Models:**
- `FileData` - Represents CSV file with name and column headers
- `QueryRequest` - Contains user query and list of FileData objects

**Environment Requirements:**
- `ANTHROPIC_API_KEY` environment variable must be set for Claude API access

**System Prompt Context:**
The Claude model is configured as a "world class data analyst" and "expert python programmer" that generates pandas-based analysis code with minimal external dependencies. Generated code must store final results in a 'result' variable in JSON-serializable format.