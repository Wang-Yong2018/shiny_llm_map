source('../../etl/llmapi.R')
test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})


test_that("chat with google gemini", {
  expect <- 'gemini|Gemini|google'
  actual <- get_llm_result('are you google gemini?',model_id='gemini',llm_type='chat')
  expect_match(actual, expect)
})

test_that("chat with openai ", {
  expect <- 'GPT|gpt'
  actual <- get_llm_result('are you openAI GPT?',model_id='gpt4',llm_type='chat')
  compare_result <- grepl(expect, actual) 
  expect_match(actual, expect)
})
