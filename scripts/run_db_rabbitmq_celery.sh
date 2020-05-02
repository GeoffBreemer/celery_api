#!/usr/bin/env bash
# Purpose:
#
# Starts the PostgreSQL database and RabbitMQ in local Docker containers, applies all
# migrations, populates the database with seed data and starts Celery.
#
# This script must be executed from: <repo path>/scripts/
# Make the script executable using: chmod u+x run_db_rabbitmq_celery.sh
#
# To generate migrations for a specific app rather than all apps set the APP_NAME
# environment variable to the name of an app. To generate migrations for all apps set
# it to an empty string.
#
# Usage:
#
# To start and prepare the local database, RabbitMQ and celery:
#
# ./run_db_rabbitmq_celery.sh
#

# Django environment variables
source constants.sh

# Change this constant to restrict migration generation to a specific app OR set it to
# an empty string to generate migrations for all apps
#export APP_NAME="data"
export APP_NAME=""


# PostgreSQL environment variables
export DB_PW="admin1234"
export DB_USER="api"
export DB_NAME="api_db"
export DB_HOST="localhost"
export DB_PORT=5432

# RabbitMQ environment variables
export RMQ_PORT=5672

# Change to the folder containing the Django settings
cd ..

# Kill any running PostgreSQL and RabbitMQ containers
echo
echo "[RUN DB MQ CELERY] - Killing and removing any running PostgreSQL and RabbitMQ Docker containers"
docker rm -f maxwell-postgresql &> /dev/null
docker rm -f postgresql_db &> /dev/null
docker rm -f unit-test-maxwell-api-postgresql &> /dev/null
docker rm -f maxwell-rabbitmq &> /dev/null

# Start the PostgreSQL container
echo
echo "[RUN DB MQ CELERY] - Starting the PostgreSQL Docker container 'maxwell-postgresql'"
docker run --name=maxwell-postgresql -d -p \
    ${DB_PORT}:${DB_PORT} \
    -e POSTGRES_PASSWORD=${DB_PW} \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_DB=${DB_NAME}   \
    postgres

# Give the container time to complete startup
sleep 1

# Start the RabbitMQ container
echo
echo "[RUN DB MQ CELERY] - Starting the RabbitMQ Docker container 'maxwell-rabbitmq'"
docker run --name=maxwell-rabbitmq -d -p \
    ${RMQ_PORT}:${RMQ_PORT} \
    rabbitmq

# Ask to make migrations
echo
echo -n "[RUN DB MQ CELERY] - Make migrations for app '${APP_NAME}' (update the script to change the app)? (y/n)? "
read answer
if [[ "$answer" != "${answer#[Yy]}" ]] ;then
    echo "[RUN DB API LOCAL] - Making migrations"
    # Create an automatic migration
    python manage.py makemigrations --settings=${DJANGO_SETTINGS_MODULE} ${APP_NAME}

    # Or use this to create an empty one:
#    python manage.py makemigrations --name bulk_tasks --empty --settings=celery_review.settings ${APP_NAME}
    read -p "[RUN DB MQ CELERY] - Made migrations. Press enter to apply them. Do not forget to commit to git."
else
    echo "[RUN DB MQ CELERY] - Not making migrations"
fi

# Apply all migrations
echo
echo "[RUN DB MQ CELERY] - Applying all Django migrations"
python manage.py migrate --settings=${DJANGO_SETTINGS_MODULE}

# Add seed data
echo
echo "[RUN DB MQ CELERY] - Adding seed data to the PostgreSQL database"
python manage.py runscript utils.add_seed_data --settings=${DJANGO_SETTINGS_MODULE}

# Start Celery
cd scripts
source run_celery.sh
