import re

from fastapi import FastAPI, UploadFile, HTTPException
from pydantic import BaseModel
from utils.prompt import filled_in_prompt
from utils.llm import submit_query

app = FastAPI()

class FileData(BaseModel):
	name: str
	columns: list[str]

class QueryRequest(BaseModel):
   query: str
   files_data: list[FileData]

@app.post("/submit-query")
async def user_query_endpoint(request: QueryRequest):
	query = request.query
	files_data = request.files_data
	user_files_data = user_files_data_formatted(files_data)
	prompt_with_query = filled_in_prompt(query, user_files_data)
	response = submit_query(prompt_with_query)
	return response

def user_files_data_formatted(files_data: FileData):
	result = ""

	for file_data in files_data:
		result = f"{result}\nFile: {file_data.name}\nHeaders: {file_data.columns}"
	
	result = result.strip()
	return result
