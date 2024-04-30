from openai import OpenAI
from os import getenv

# gets API Key from environment variable OPENAI_API_KEY
def get_llm_connection(model_name="openai/gpt-3.5-turbo"):
  apt_key = getenv('OPENROUTER_API_KEY') 
  base_url = "https://openrouter.ai/api/v1"
  llm_connection = OpenAI( base_url=base_url, api_key=apt_key)
  return llm_connection


def py_chat(llm_connection, 
         prompt=None,
         history=None, 
         model_name="openai/gpt-3.5-turbo"):
  if (prompt is not None):
    messages=[ { "role": "user", "content": prompt } ]
    history= llm_connection.chat.completions.create( model=model_name,
                                                    messages=messages)
  return history

#llm_conn = get_llm_connection()
#result = chat(llm_conn, prompt='what is your name ?')
#print(result)
