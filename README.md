## Contents
<!-- Table of Contents -->
[#1. Purpose](#purpose)  
[#2. Core Concept](#core_concept)  
[#3. Features snapshot](#features)  
- [#3.1 Multi Ask](#multi_ask)  
- [#3.2 Analyze Image](#analyze_image)  
- [#3.3 Probe DB](#probe_db)  

[#4. How to Use](#howto)  
- [#4.1. web demo](#web_demo)  
- [#4.2. rstudo run app](#rstudio)  
- [#4.3 rstudio console call](#console)  

[#5. Q&A](#question)  
[#6. Citation](#citation)  
[source code](https://github.com/Wang-Yong2018/shiny_llm_map)

## 1. Purpose
<a id="purpose"></a>

Shiny LLM map is designed to provide a user-friendly interface for playing with multiple large language models easily, the core features are MAP. This is the [web demo]( http://r7prz5-yong-wang.shinyapps.io/shiny_llm_map/)

|||
|------------------------------------|------------------------------------|
|<img src="images/clipboard-793703704.png" width="320" height="auto"> | \- **Multi ASK**, Ask text question & chat with multiple models ,<br />- **Analyze IMG**, Vision picture topic and contents <br />- **Probe DB**, Evaluate a database value, query data with nature language |

## 2. Core Concept
<a id="core_concept"></a>
The core concept of Shiny llm map app is value driven which including -

-   **Multi connection**, instead of connect to one model, user ask one or more models work for task via drop down list. Openrouter API service was choice as base connector service. It is not free, but a api connectors to provide the [best models & prices](https://openrouter.ai/models) for your prompts service.

-   **More reproducible**, instead of get random geneated answers, using predefine parameter to let model answer reproducible.(still testing)

-   **Less dependence,** instead of using various models api library and agent library like lang chain, it is developed based on R an CRAN. (shiny, httr2, purrr, tidyverse, jsonlite, box and others r packages used)

## 3. Features snapshot
<a id="features"></a>

### 3.1 Multi Ask
<a id="multi_ask"></a>
Ask one question, all the selected models will response the answer based on their model understanding. You may open eyes to check how different or how exact same of those answer.

|||
|------------------------------------|------------------------------------|
| <img src="images/clipboard-1336060026.png" width="480" height="auto"> | With multi ask feature, you just ask and select desired one., shiny LLM map will collect answer for you. <br/><br /> Besides, the cost of for heavy using large language model is becoming a concern now. If model give same quality answer, why not use low cost model for common question. The fashion and popular models will be responsible for hard question. |

### 3.2 Analyze Image
<a id="analyze_image"></a>

image + model + your question + click = analyze picture answer.

|||
|------------------------------------|------------------------------------|
| !<img src="images/clipboard-3356107549.png" width="480" height="auto"> | You can upload local image to app, and select mulit-mode supported large language model(such as gemini, and chatgpt4v, chatgpt 4o). <br /> <br /> The app will send both picture and your question(prompt ) to specific models ans show the answer. |

### 3.3 Probe DB
<a id="probe_db"></a>

The probe DB feature is targeted to help people use large language mode to evaluation value, catalog list , query their data.

by combined the database schema and statistic information

|||
|------------------------------------|------------------------------------|
| 1\. Evaluation <br /> <img src="images/clipboard-4012269144.png" width="480" height="auto">                                 | \- In the past, expert know their industry knowledge at expert level. However, they will be beginner level when jump into new industry. As ordinary, they will face a stiff learning curve as well. But I think LLM can change it. <br /> <br /> - Instead of text to sql application, I put the evaluation data business value and opportunities as the 1st feature. LLM can help user explore this section instance without hiring consultant and spent long waiting time. <br /><br /> - For example, the hospital datasets been evaluated by LLM for how to improve patient care, operational efficiency and etc. |
| 2\. follow the opportunities to ask question - <img src="images/clipboard-1191591584.png" width="480" height="auto">        | Using natural language to ask how to improve patience care.|
| 3\. Get data instantly <br /><img src="images/clipboard-18537938.png" width="480" height="auto"> | the current patient appointment showed instantly.|
|||
| 4\. Inside work <br />||
| \- APP make Prompt from user question and others <br /><img src="images/clipboard-669495036.png" width="480" height="auto"> | After received user question(natural language), shiny llm map convert it to prompt with database schema info |
| \- LLM generate SQL based on sytem prompt <br /> <img src="images/clipboard-1179619434.png" width="480" height="auto"> | <br /> - LLM provide the sql query base on natural language question. <br /> - Shiny llm app use the sql query get local data and show it |
| 5\. Openbox - Sample Dataset <br /> <img src="images/clipboard-3153122393.png" width="480" height="auto">                   | \- Popular database samples is open box ready. <br /> - Three medium size database extracted from spider NLP2SQL project and ready for demo purpose <br /><br /> - a. Music - the famous chinook datasets <br /> - b. Dvd Rental - the famous sakila dataset <br /> - c. Hospital - a hospital operation databse|

## 4. How to Use
<a id="howto"></a>

To use the shiny llm map , you has two choices:

### 4.1. Web demo  
<a id="web_demo"></a>

just open below link for fun, [web demo](http://r7prz5-yong-wang.shinyapps.io/shiny_llm_map)

### 4.2. Run App @rstudio 
<a id="rstudio"></a>

if you are familiar with Rstudio, clone it as your new project and have fun.

| step | note |
|---| ----|
|||
| 1\. clone new project from github <br /> <img src="images/clipboard-1024058564.png" width="480" height="auto">) | the github url is : [shiny_llm_map](https://github.com/Wang-Yong2018/shiny_llm_map)                 |
| 2 Get OpenAPI key <img src="images/clipboard-3470272520.png" width="480" height="auto">                         | \- link: <https://openrouter.ai/keys> <br /> - There are free models but popular model charged per usage. |
| 3\. fill .Renviron file with key <br /> <img src="images/clipboard-3817247199.png" width="480" height="auto">)  | write the api key in to .Renviron under project root folder |
| 4\. Run it <br /><img src="images/clipboard-2052786117.png" width="480" height="auto">                          | Launch it by open app.R and click Run button|
| 5\. Play it <br /><img src="images/clipboard-1179619434.png" width="480" height="auto">                         | Enjoy it and have fun!|

### 4.3 call function from Rstudio console
<a id="console"></a>


If the source code has been download to local computer, and open the project at Rstudio. You can call some function directly

-   step 1, open the llmapi.R under etl folder, and click the source to load the script. Note: directly source('../etl/llmapi.R') will report Error, it has be to sourced by Rstudio file menu.

```{r}
source('./etl/llmapi.R')
llm_result <- get_llm_result(prompt='hello ai world! which orgination create you?', model_id='gpt35',llm_type='chat')
ai_result <- get_ai_result(llm_result,ai_type='chat')
print(ai_result)
# $role
# [1] "assistant"

# $content
# [1] "Hello! I am glad to assist you. I was created by a team of programmers and developers at OpenAI. If you have any questions or need help with anything, feel free to ask!"
```

## 5. Q&A
<a id="question"></a>

|||
|------------------------------------|------------------------------------|
| 5.1 Q:the app response is unauthorized<br /> <img src="images/clipboard-3621734598.png" width="480" height="auto"> | \- a. pls check your openrouter api is configured and valid.<br /> - b. The api key should be write in .Renviron file <br /> <img src="images/clipboard-3817247199.png" width="480" height="auto"><br /> - c. the api key should be valid and not over limit <br /><img src="images/clipboard-1110060166.png" width="480" height="auto">|

## 6. Citation
<a id="citation"></a>

If you use this code for your research or project, please cite it as follows:

```         
OpenRouter[2024]. Quick Start. Retrieved from [https://openrouter.ai/docs/quick-start].
```

```         
Google[2024]. https://github.com/google-gemini/cookbook. Retrieved from [https://github.com/google-gemini/cookbook].
```

```         
OpenAI[2024]. openai-cookbook. Retrieved from [https://github.com/openai/openai-cookbook].
```

```         
Hadley Wickham (2023). httr2. GitHub Repository. Retrieved from [https://github.com/r-lib/httr2/].
```

```         
Hadley Wickham (2023). Functional Programming Tools • purrr. GitHub Repository. Retrieved from [https://github.com/tidyverse/purrr/].
```

```         
Jinhwan Kim (2023). Use google’s Gemini in R with R package “gemini.R”. GitHub Repository. Retrieved from [https://github.com/jhk0530/gemini.R].
```
