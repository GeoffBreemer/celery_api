#!/usr/bin/env bash
# Purpose:
#
# Starts the PostgreSQL database in a local Docker container, applies all migrations,
# populates it with seed data and, optionally, starts the Django server locally.
#
# This script must be executed from: <repo path>/api/scripts/
# Make the script executable using: chmod u+x run_db_and_api_local.sh
#
# This script is only used by developers. It is NOT used by the QA Test or k8s.
#
# To generate migrations for a specific app rather than all apps set the APP_NAME
# environment variable to the name of an app. To generate migrations for all apps set
# it to an empty string.
#
# Usage:
#
# To start and prepare the local database:
#
# ./run_db_and_api_local.sh
#
# To start and prepare the local database AND start the Django server locally:
#
# ./run_db_and_api_local.sh <any_string>
#

# Change this constant to restrict migration generation to a specific app OR set it to
# an empty string to generate migrations for all apps
#export APP_NAME="analytics"
#export APP_NAME="configuration"
#export APP_NAME="data"
#export APP_NAME="recommendations"
#export APP_NAME="users"
export APP_NAME=""

# PostgreSQL environment variables
export DB_PW="admin1234"
export DB_USER="api"
export DB_NAME="api_db"
export DB_HOST="localhost"
export DB_PORT=5432
export DJANGO_SETTINGS_MODULE="maxwell_api.settings.local_dev"

# Change to the folder containing the Django settings
cd ..

# Kill any running PostgreSQL containers
echo
echo "[RUN DB API LOCAL] - Killing and removing any running PostgreSQL Docker containers named 'postgresql_db', 'unit-test-maxwell-api-postgresql' and 'maxwell-postgresql'"
docker rm -f maxwell-postgresql &> /dev/null
docker rm -f postgresql_db &> /dev/null
docker rm -f unit-test-maxwell-api-postgresql &> /dev/null

# Start the PostgreSQL container
echo
echo "[RUN DB API LOCAL] - Starting the PostgreSQL Docker container 'maxwell-postgresql'"
docker run --name=maxwell-postgresql -d -p ${DB_PORT}:${DB_PORT} \
    -e POSTGRES_PASSWORD=${DB_PW} \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_DB=${DB_NAME}   \
    postgres

# Make migrations if desired
echo
echo -n "[RUN DB API LOCAL] - Make migrations for app '${APP_NAME}' (update the script to change the app)? (y/n)? "
read answer
if [[ "$answer" != "${answer#[Yy]}" ]] ;then
    echo "[RUN DB API LOCAL] - Making migrations"
    # Create an automatic migration
    python manage.py makemigrations --settings=celery_review.settings ${APP_NAME}

    # Or use this to create an empty one:
#    python manage.py makemigrations --name bulk_tasks --empty --settings=celery_review.settings ${APP_NAME}
    read -p "[RUN DB API LOCAL] - Made migrations. Press enter to apply them. Do not forget to commit to git."
else
    echo "[RUN DB API LOCAL] - Not making migrations"
fi

# Apply all migrations
echo
echo "[RUN DB API LOCAL] - Applying all Django migrations"
python manage.py migrate --settings=celery_review.settings

# Add seed data
echo
echo "[RUN DB API LOCAL] - Adding seed data to the PostgreSQL database"
python manage.py runscript utils.add_seed_data --settings=celery_review.settings

# Execute unit tests if desired
echo
echo -n "[RUN DB API LOCAL] - Execute unit tests? (y/n)? "
read answer
if [[ "$answer" != "${answer#[Yy]}" ]] ;then
    echo "[RUN DB API LOCAL] - Executing unit tests"
    python manage.py test . --settings=maxwell_api.celery_review.local_dev --parallel
else
    echo "[RUN DB API LOCAL] - Not executing unit tests"
fi

# Start the Django server locally
if [[ -z "$1" ]]
    then
    echo
    echo "[RUN DB API LOCAL] - NOT starting the Django server locally"
    echo "[RUN DB API LOCAL] - Done"
else
    echo
    echo "[RUN DB API LOCAL] - Starting the Django server on: http://127.0.0.1:8000/admin/"
    python manage.py runserver --settings=celery_review.settings.local_dev
fi
