# langchain
from langchain_google_genai import ChatGoogleGenerativeAI
import os

def get_answer(prompt='introduce your self'):
  # get gemini answer from google
  # assumption: 
  ## 1. API key  GOOGLE_API_KEY preset in os environment
  ## 2. network accessable. If in certain Countries, google will not allow it be used.
  
  llm = ChatGoogleGenerativeAI(model="gemini-pro")
  answer = llm.invoke(prompt)
  return(answer.content)
