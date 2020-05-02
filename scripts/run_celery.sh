#!/usr/bin/env bash

# Django environment variables
source constants.sh

# Start Celery
echo
echo -n "[RUN CELERY] - Starting Celery "
cd ..
celery -A ${PROJECT_NAME} worker -l info
