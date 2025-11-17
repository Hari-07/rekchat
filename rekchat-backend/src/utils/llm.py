import anthropic

client = anthropic.Anthropic()

def submit_query(query: str):
	message = client.messages.create(
		model="claude-3-5-haiku-20241022",
		max_tokens=1000,
		temperature=1,
		system="You are a world class data analyst, an expert python programmer that prefers to use external libraries very minimally.",
		messages=[
			{
				"role": "user",
				"content": [
					{
						"type": "text",
						"text": query
					}
				]
			}
		]
	)

	response = message.content[0].text
	return response