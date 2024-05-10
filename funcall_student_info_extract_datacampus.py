from openai import OpenAI
from os import getenv
import json
# gets API Key from environment variable OPENAI_API_KEY
client = OpenAI(
  base_url="https://openrouter.ai/api/v1",
  api_key='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'
)

student_1_description = "David Nguyen is a sophomore majoring in computer science at Stanford University. He is Asian American and has a 3.8 GPA. David is known for his programming skills and is an active member of the university's Robotics Club. He hopes to pursue a career in artificial intelligence after graduating."
# A simple prompt to extract information from "student_description" in a JSON format.
student_2_description="Ravi Patel is a sophomore majoring in computer science at the University of Michigan. He is South Asian Indian American and has a 3.7 GPA. Ravi is an active member of the university's Chess Club and the South Asian Student Association. He hopes to pursue a career in software engineering after graduating."
prompt1 = f'''
Please extract the following information from the given text and return it as a JSON object:

name
major
school
grades
club

This is the body of text to extract the information from:
{student_1_description}
'''

prompt2 = f'''
Please extract the following information from the given text and return it as a JSON object:

name
major
school
grades
club

This is the body of text to extract the information from:
{student_2_description}
'''

school_1_description = "Stanford University is a private research university located in Stanford, California, United States. It was founded in 1885 by Leland Stanford and his wife, Jane Stanford, in memory of their only child, Leland Stanford Jr. The university is ranked #5 in the world by QS World University Rankings. It has over 17,000 students, including about 7,600 undergraduates and 9,500 graduates23. "
student_custom_functions = [
    {
        'name': 'extract_student_info',
        'description': 'Get the student information from the body of the input text',
        'parameters': {
            'type': 'object',
            'properties': {
                'name': {
                    'type': 'string',
                    'description': 'Name of the person'
                },
                'major': {
                    'type': 'string',
                    'description': 'Major subject.'
                },
                'school': {
                    'type': 'string',
                    'description': 'The university name.'
                },
                'grades': {
                    'type': 'integer',
                    'description': 'GPA of the student.'
                },
                'club': {
                    'type': 'string',
                    'description': 'School club for extracurricular activities. '
                }
                
            }
        }
    }
]

custom_functions = [
    {
        'name': 'extract_student_info',
        'description': 'Get the student information from the body of the input text',
        'parameters': {
            'type': 'object',
            'properties': {
                'name': {
                    'type': 'string',
                    'description': 'Name of the person'
                },
                'major': {
                    'type': 'string',
                    'description': 'Major subject.'
                },
                'school': {
                    'type': 'string',
                    'description': 'The university name.'
                },
                'grades': {
                    'type': 'integer',
                    'description': 'GPA of the student.'
                },
                'club': {
                    'type': 'string',
                    'description': 'School club for extracurricular activities. '
                }
                
            }
        }
    },
    {
        'name': 'extract_school_info',
        'description': 'Get the school information from the body of the input text',
        'parameters': {
            'type': 'object',
            'properties': {
                'name': {
                    'type': 'string',
                    'description': 'Name of the school.'
                },
                'ranking': {
                    'type': 'integer',
                    'description': 'QS world ranking of the school.'
                },
                'country': {
                    'type': 'string',
                    'description': 'Country of the school.'
                },
                'no_of_students': {
                    'type': 'integer',
                    'description': 'Number of students enrolled in the school.'
                }
            }
        }
    }
]
description = [student_1_description, school_1_description]
for i in description:
    response = client.chat.completions.create(
        model = 'gpt-3.5-turbo',
        messages = [{'role': 'user', 'content': i}],
        functions = custom_functions,
        function_call = 'auto'
    )

    # Loading the response as a JSON object
    message = response.choices[0].message
    json_response = json.loads(message.function_call.arguments)
    print(json_response)
