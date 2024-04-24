# this docs is used to connect google gemini restapi with R language world
# based on the library httr2 , purrr, memoise, cachem,box , rlang and etc

# gemini api docs link: https://ai.google.dev/gemini-api/docs/get-started/rest?gemini_and_content_based_apis#set_up_your_api_key

# Library loading 
## httr2 method import for use curl in tidy mode 
box::use(httr2[request, req_perform,
               resp_status,req_retry,req_error,
               req_body_json, req_user_agent,
               req_url_query, req_url_path_append,
               resp_body_json])

## purrr method import for interative job
box::use(purrr[map_dfr, pluck])

## memoise method import for cach result 
box::use(cachem[cache_disk],
         memoise[memoise])

## dplyr package import for data manupilate
box::use(dplyr[as_tibble])

## rlang package for exception handling
box::use(rlang[abort,warn])

## reticulate for call python package
library(reticulate)
use_python('c:/Python/Python312/python.exe')
source_python('./etl/llm_gemini.py')

cache_dir <- cache_disk("./cache",max_age = 3600*24)

# Gemini and Content based APIs

## Text-only input
### Use the generateContent method to generate a response from the model given an input message. If the input contains only text, use the gemini-pro model.
### 
### 
### curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GOOGLE_API_KEY \
### -H 'Content-Type: application/json' \
### -X POST \
### -d '{
###       "contents": [{
###         "parts":[{
###           "text": "Write a story about a magic backpack."}]}]}' 2> /dev/null

text_input <- function(prompt, use_cache = TRUE) {
  # The generate_content method can handle a wide variety of use cases,
  # including multi-turn chat and multimodal input, depending on what the
  # underlying model supports. 
  # The available models only support text and images as input, and text as output.
  # TODO textinput 
  ## 1. candidates, 
  ## 2. stream
  ## 3. prompt_feedback
  fast_text_input <- memoise(py_text_input, 
                             cache = cache_dir)
  text_output <- '' 
  
  if ( use_cache ){
    
   text_output <- fast_text_input(prompt) 
  }else{
    
   text_output <- py_text_input(prompt) 
  }
  
  return(text_output) 
}

## Text-and-image input
### If the input contains both text and image, use the gemini-pro-vision model. The following snippets help you build a request and send it to the REST API.
### 
### 
### curl -o image.jpg https://storage.googleapis.com/generativeai-downloads/images/scones.jpg
### 
### % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
### Dload  Upload   Total   Spent    Left  Speed
### 100  385k  100  385k    0     0  2053k      0 --:--:-- --:--:-- --:--:-- 2050k
### 
### import PIL.Image
### 
### img = PIL.Image.open("image.jpg")
### img.resize((512, int(img.height*512/img.width)))

text_image_input <- function(image_path,prompt,use_cache = TRUE){
  fast_text_image_input <- memoise(py_text_image_input, 
                             cache = cache_dir)
  text_image_output <- '' 
  
  if(use_cache){
    
    text_image_output <- fast_text_image_input(prompt, image_path=image_path) 
  }else{
    
    text_image_output <- py_text_image_input(prompt=prompt, image_path = image_path) 
  }
  
  return(text_image_output) 
}

## Multi-turn conversations (chat)
### Using Gemini, you can build freeform conversations across multiple turns.
### 
### 
### curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GOOGLE_API_KEY \
### -H 'Content-Type: application/json' \
### -X POST \
### -d '{
###       "contents": [
###         {"role":"user",
###          "parts":[{
###            "text": "Write the first line of a story about a magic backpack."}]},
###         {"role": "model",
###          "parts":[{
###            "text": "In the bustling city of Meadow brook, lived a young girl named Sophie. She was a bright and curious soul with an imaginative mind."}]},
###         {"role": "user",
###          "parts":[{
###            "text": "Can you set it in a quiet village in 1600s France?"}]},
###       ]
###     }' 2> /dev/null | grep "text"

multi_turn_conversation <- function(){
  # TODO
}

chat <- function(prompt,history =NULL,  use_cache = TRUE){
 # Chat conversations
 # Gemini enables you to have freeform conversations across multiple turns. 
 # The ChatSession class simplifies the process by managing the state of the 
 # conversation, so unlike with generate_content, you do not have to store the
 # conversation history as a list.
  
  fast_py_chat <- memoise(py_chat, 
                           cache = cache_dir)

  text_output <- '' 
  
  last_history <- py_chat(prompt,history) 
  
  text_output <- last_history|>pluck(-1, 'parts',-1,'text') 
  chat_history <- list(history=last_history,
                       text_output = text_output)
  return(chat_history)  
}


## Configuration
### Every prompt you send to the model includes parameter values that control how the model generates a response. The model can generate different results for different parameter values. Learn more about model parameters.
### 
### Also, you can use safety settings to adjust the likelihood of getting responses that may be considered harmful. By default, safety settings block content with medium and/or high probability of being unsafe content across all dimensions. Learn more about safety settings.
### 
### The following example specifies values for all the parameters of the generateContent method.
### 

configuration <- function(){
  # TODO
}

## Stream Generate Content
### The generateContent method returns a response after completing the entire generation process. You can achieve faster interactions by not waiting for the entire result, and instead use streamGenerateContent to return partial results.
### 
### Important: Be sure to set alt=sse in the URL parameters. Each line is a GenerateContentResponse object with a chunk of the output text in candidates[0].content.parts[0].text.
### 
### !curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:streamGenerateContent?alt=sse&key=${GOOGLE_API_KEY}" \
###    -H 'Content-Type: application/json' \
###    --no-buffer \
###    -d '{ "contents":[{"parts":[{"text": "Write long a story about a magic backpack."}]}]}' \
###    2> /dev/null

stream_generate_content <- function(){
  # TODO 
}
## Count tokens
### When using long prompts, it might be useful to count tokens before sending any content to the model.
### 
### 
### curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:countTokens?key=$GOOGLE_API_KEY \
### -H 'Content-Type: application/json' \
### -X POST \
### -d '{
###       "contents": [{
###         "parts":[{
###           "text": "Write a story about a magic backpack."}]}]}' > response.json
count_tokens <- function(){
  # TODO
}

## Embedding
### Embedding is a technique used to represent information as a list of floating point numbers in an array. With Gemini, you can represent text (words, sentences, and blocks of text) in a vectorized form, making it easier to compare and contrast embeddings. For example, two texts that share a similar subject matter or sentiment should have similar embeddings, which can be identified through mathematical comparison techniques such as cosine similarity.
### Use the embedding-001 model with either embedContents or batchEmbedContents:
###   
###   curl https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedContent?key=$GOOGLE_API_KEY \
###         -H 'Content-Type: application/json' \
###         -X POST \
###         -d '{
###         "model": "models/embedding-001",
###         "content": {
###         "parts":[{
###           "text": "Write a story about a magic backpack."}]} }' 2> /dev/null | head
embbeding <- function(){
  # TODO
}

# model info
## get model
### If you GET a model's URL, the API uses the get method to return information about that model such as version, display name, input token limit, etc.
###
###   curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro?key=$GOOGLE_API_KEY
get_model <- function(){
  #TODO
}
## List models
###  If you GET the models directory, it uses the list method to list all of the models available through the API, including both the Gemini and PaLM family models.
### 
###    curl https://generativelanguage.googleapis.com/v1beta/models?key=$GOOGLE_API_KEY

list_models <- function(){
  # cache result from python call , and store the data in disk
  fast_get_list_models <- memoise(py_get_list_models,cache=cache_dir)
  models_name <- fast_get_list_models()
  return(models_name)
}
