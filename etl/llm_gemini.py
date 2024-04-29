import os
import pathlib
import textwrap

from IPython.display import display
from IPython.display import Markdown
import PIL.Image

import google.generativeai as genai
# init the google generativeai api key globally
api_key=os.environ['GOOGLE_API_KEY']
genai.configure(api_key=api_key)


def multiply(a:float, b:float):
    """returns a * b."""
    return a*b
  
  
# format the answer result into markdown format
def py_to_markdown(text):
  text = text.replace('•', '  *')
  return Markdown(textwrap.indent(text, '> ', predicate=lambda _: True))

def py_get_list_models():
  name_list = []
  for m in genai.list_models():
   if 'generateContent' in m.supported_generation_methods:
      name_list.append(m.name)
  return(name_list)
    
def py_text_input(prompt,to_markdown=False):
  model = genai.GenerativeModel('gemini-pro')
  response = model.generate_content(prompt)
  if to_markdown==True:
    text_output = py_to_markdown(response.text)
  else:
    text_output = response.text
    
  return(text_output)

def py_text_image_input(prompt, image_path,to_markdown=False):
  model = genai.GenerativeModel('gemini-pro-vision')
  
  img = PIL.Image.open(image_path)
  
  response = model.generate_content([prompt,img],stream=True)
  
  response.resolve()
  
  if to_markdown==True:
    text_output = py_to_markdown(response.text)
  else:
    text_output = response.text
    
  return(text_output)

def py_chat(prompt, history=None,to_markdown=False):
  
  model = genai.GenerativeModel('gemini-pro',
   tools=[multiply])
  if history is None:
    history=[]
  
  chat_id = model.start_chat(history=history,enable_automatic_function_calling=True)
  
  response = chat_id.send_message(prompt)
  updated_history = chat_id.history  
  # 
  # if to_markdown==True:
  #   text_output = py_to_markdown(response.text)
  # else:
  #   text_output = response.text
    
  return(updated_history)  


def py_embedding(content=None): 
  result = genai.embed_content(
     model="models/embedding-001",
     content=content,
     task_type="retrieval_document",
     title="Embedding of single string")
  return(result)

