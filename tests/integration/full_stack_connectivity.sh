#!/bin/sh
set -e

echo "Starting full stack connectivity test..."

echo "Postgres: checking availability"
PGPASSWORD=${DB_PASSWORD:?DB_PASSWORD must be set} psql -h ${DB_HOST:-localhost} -p ${DB_PORT:-5432} -U ${DB_USER:-app_user} -d ${DB_NAME:-app_db} -c 'SELECT 1' | grep -q 1

echo "Redis: checking availability"
redis-cli -h ${REDIS_HOST:-localhost} -p ${REDIS_PORT:-6379} ping | grep -q PONG

echo "RabbitMQ: checking availability"
curl -fsS -u ${RABBITMQ_USER:-guest}:${RABBITMQ_PASS:-guest} http://localhost:15672/api/overview >/dev/null

echo "Full stack connectivity test passed!"
