source('../../etl/llmapi.R')
test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})


test_that("image recognize with gemin", {
  expect <- 'halmet|hat|Hat|Halmet'
  actual <- get_llm_result('what are the personal safety equipment in the picutre?',
                           model_id='gemini',llm_type='img',img_url = './halmet.png')
  compare_result <- grepl(expect, actual) 
  expect_match(actual, expect)
})

test_that("image recognize with openai", {
  expect <- 'halmet|hat|Hat|Halmet'
  actual <- get_llm_result('what are the personal safety equipment in the picutre?',
                           model_id='gpt4v',llm_type='img',img_url = './halmet.png')
  compare_result <- grepl(expect, actual) 
  expect_match(actual, expect)
})