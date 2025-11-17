import httpx
import pandas as pd
import re
import json
import traceback
import signal
import ast
import asyncio
from datetime import datetime
from contextlib import contextmanager

from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.responses import StreamingResponse
from pathlib import Path
from typing import List, Dict, Any, AsyncGenerator

app = FastAPI(
    title = "Embedded backend"
)

files_data = []

# Security patterns to detect
DANGEROUS_PATTERNS = [
    'import os', 'import sys', 'import subprocess', 'import shutil',
    'import socket', 'import requests', 'import urllib', 'import http',
    'exec(', 'eval(', 'compile(', '__import__', 
    'open(', 'file(', 'input(', 'raw_input(',
    'exit(', 'quit(', 'breakpoint('
]

def has_security_issues(code: str) -> bool:
    """Check if code contains potentially dangerous patterns"""
    code_lower = code.lower()
    return any(pattern in code_lower for pattern in DANGEROUS_PATTERNS)

async def get_safe_code(query: str, max_retries: int = 1) -> str:
    """Re-prompt LLM to generate safer code"""
    for retry in range(max_retries):
        try:
            async with httpx.AsyncClient(timeout=None) as client:
                safety_prompt = f"""
                The previous code contained potentially unsafe operations. 
                Please generate a safer version that only uses pandas, numpy, math, and datetime libraries.
                Avoid file system operations, network requests, and system calls.
                
                Original query: {query}
                
                Focus on data analysis operations only.
                """
                
                response = await client.post(
                    "http://127.0.0.1:8000/submit-query",
                    json={"files_data": files_data, "query": safety_prompt}
                )
                
                response_text = response.text
                code_pattern = r"<python_code>([\s\S]*?)</python_code>"
                code_match = re.search(code_pattern, response_text)
                
                if code_match:
                    new_code = code_match.group(1).strip().replace('\\n', '\n')
                    if not has_security_issues(new_code):
                        return new_code
                        
        except Exception as e:
            print(f"Safety retry {retry + 1} failed: {e}")
            continue
    
    # If all retries failed, return None to indicate failure
    return None

@app.post("/upload-file")
async def process_files(files: list[UploadFile]):
    global files_data
    files_data = []
    for file in files:
        # validate CSV file
        file_name = file.filename
        file_extension = Path(file.filename).suffix.lower()
        if file_extension != ".csv":
            raise HTTPException(status_code = 400)

        df_header = pd.read_csv(file.file, nrows = 0)
        headers = df_header.columns.tolist()

        file.file.seek(0)
        with open(file_name, "wb") as f:
            content = await file.read()
            f.write(content)

        file_data = {
            "name": file_name,
            "columns": headers
        }
        files_data.append(file_data)
    return files_data

async def process_query_logic(query: str) -> AsyncGenerator[str, None]:
    """Core query processing logic that yields SSE events"""
    try:
        print(f"[{datetime.now().strftime('%H:%M:%S.%f')[:-3]}] Starting query processing for: {query}")
        # Much longer timeout - 60 seconds
        async with httpx.AsyncClient(timeout=None) as client:
            response = await client.post(
                "http://127.0.0.1:8000/submit-query",
                json={"files_data": files_data, "query": query}
            )
            response_text = response.text
            # response_text = llm_response_2

            # Emit SSE event after receiving LLM response
            status_event = "data: " + json.dumps({"type": "status", "message": "Code received"}) + "\n\n"
            yield status_event

            # Process the code
            code_pattern = r"<python_code>([\s\S]*?)</python_code>"
            code_match = re.search(code_pattern, response_text)
            
            if not code_match:
                yield "data: " + json.dumps({
                    "type": "complete",
                    "result": None,
                    "explanation": "No Python code found in LLM response",
                    "success": False
                }) + "\n\n"
                return
            
            code = code_match.group(1).strip()
            # Convert literal \n to actual newlines
            code = code.replace('\\n', '\n')
            code = re.sub(r'\\\s*\n', '\n ', code)
            
            # Security check and retry if needed
            if has_security_issues(code):
                print("Security issues detected, attempting to get safer code...")
                safe_code = await get_safe_code(query)
                if safe_code is None:
                    yield "data: " + json.dumps({
                        "type": "complete",
                        "result": None,
                        "explanation": "Generated code contains potentially unsafe operations and could not be made safe. Please modify your query to focus on data analysis only.",
                        "success": False
                    }) + "\n\n"
                    return
                code = safe_code
                print(f"Using safer code: {repr(code)}")
            
            exec_namespace = {}
            def execute_code():
                exec_namespace = {}
                exec(code, exec_namespace)
                return exec_namespace

            exec_namespace = await asyncio.to_thread(execute_code)
            # exec(code, exec_namespace)
            
            if 'result' not in exec_namespace:
                yield "data: " + json.dumps({
                    "type": "complete",
                    "result": None,
                    "explanation": "Code executed but no 'result' variable found",
                    "success": False
                }) + "\n\n"
                return
            
            result = exec_namespace['result']
            
            # Convert pandas DataFrame to dict if needed for JSON serialization
            if hasattr(result, 'to_dict'):
                result = result.to_dict('records')
            
            complete_event = "data: " + json.dumps({
                "type": "complete",
                "result": result,
                "explanation": "Code executed successfully",
                "success": True
            }) + "\n\n"
            yield complete_event

    except httpx.ReadTimeout as e:
        print(f"Read timeout after extended wait: {e}")
        yield "data: " + json.dumps({
            "type": "complete",
            "result": None,
            "explanation": "Request timeout - main backend took too long to respond",
            "success": False
        }) + "\n\n"
    except Exception as e:
        error_msg = f"Error executing code: {type(e).__name__}: {str(e)}"
        print(error_msg)
        print(code)
        yield "data: " + json.dumps({
            "type": "complete",
            "result": None,
            "explanation": error_msg,
            "success": False
        }) + "\n\n"


@app.post("/submit-query")
async def submit_query(query: str) -> Dict[str, Any]:
    """Original endpoint - collects all events and returns final result"""
    result_data = None
    async for event in process_query_logic(query):
        # Parse the SSE event to get the data
        if event.startswith("data: "):
            event_data = json.loads(event[6:].strip())
            if event_data.get("type") == "complete":
                result_data = {
                    "result": event_data.get("result"),
                    "explanation": event_data.get("explanation"),
                    "success": event_data.get("success")
                }
    return result_data or {
        "result": None,
        "explanation": "No result received",
        "success": False
    }


@app.post("/submit-query-stream")
async def submit_query_stream(query: str):
    """SSE endpoint that streams events in real-time"""
    async def event_stream():
        async for event in process_query_logic(query):
            print(f"[{datetime.now().strftime('%H:%M:%S.%f')[:-3]}] FastAPI yielding event: {repr(event[:50])}...")
            yield event
            # Force flush - this ensures immediate delivery
            yield ""
    
    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disable nginx buffering
        }
    )
