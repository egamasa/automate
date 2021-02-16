import os

SCRIPT_NAME = 'UsappyGame'

# Apply "True" if run on serverless platforn like Google Cloud Functions.
USE_ENV_VARIABLE = True

if USE_ENV_VARIABLE:
    EMAIL = os.getenv('EMAIL')
    PASS = os.getenv('PASS')
else:
    # Apply account data when NOT use environment variables.
    EMAIL = ''
    PASS = ''
