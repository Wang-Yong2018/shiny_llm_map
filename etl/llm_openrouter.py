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
         model_id=""):
    mode_name_map = { 
      "gpt35": "openai/gpt-3.5-turbo", 
      "gpt4": "openai/gpt-4",
      "gpt4t": "openai/gpt-4-turbo",
      "gpt4v": "openai/gpt-4-vision-preview",
      'gemini': "google/gemini-pro-1.5" }
    model_name = mode_name_map.get(model_id,'google/gemini-pro-1.5')
    
    if (prompt is not None):
      messages=[ { "role": "user", "content": prompt } ]
      history= llm_connection.chat.completions.create(model=model_name,messages=messages)
    
    return history

def py_image_chat(llm_connection, 
          prompt=None,
          history=None,
          model_id=""):
            
    mode_name_map = { 
      "gpt35": "openai/gpt-3.5-turbo", 
      "gpt4": "openai/gpt-4",
      "gpt4t": "openai/gpt-4-turbo",
      "gpt4v": "openai/gpt-4-vision-preview",
      'gemini': "google/gemini-pro-1.5" }
    model_name = mode_name_map.get(model_id,'google/gemini-pro-1.5')       
    
    if (prompt is not None):
      messages=[ { "role": "user", "content": prompt } ]
      history= llm_connection.chat.completions.create(model=model_name,messages=messages)
    
    return history
    
def test_or():
  
  import requests
  import json
  
  response = requests.post(
    url="https://openrouter.ai/api/v1/chat/completions",
    headers={
      "Authorization": f"Bearer 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",
      "HTTP-Referer": f"YOUR_SITE_URL", # Optional, for including your app on openrouter.ai rankings.
      "X-Title": f"YOUR_APP_NAME", # Optional. Shows in rankings on openrouter.ai.
    },
    data=json.dumps({ "model": "google/gemini-pro-vision", # Optional
                      "messages": [ { "role": "user", 
                                      "content": "What is the meaning of life?" 
                                      } ]
                                      }) )
  return(response)
  

