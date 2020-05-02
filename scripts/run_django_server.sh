#!/usr/bin/env bash
# Django environment variables
source constants.sh

echo
echo "[RUN DJANGO SERVER] - Starting the Django server on: http://127.0.0.1:8000/"
cd ..
python manage.py runserver --settings=${DJANGO_SETTINGS_MODULE}
