#!/bin/bash
set -e

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Avvio applicazione Flask ===${NC}"

# Carica il file .env se esiste
if [ -f /app/.env ]; then
  echo -e "${GREEN}✓ Caricamento variabili da .env${NC}"
  export $(grep -v '^#' /app/.env | xargs)
fi

# Verifica che DATABASE_URL sia definito
if [ -z "$DATABASE_URL" ]; then
  echo -e "${RED}✗ Errore: DATABASE_URL non è definito${NC}"
  exit 1
fi

# Imposta PYTHONPATH
export PYTHONPATH=/app:$PYTHONPATH

# Aspetta che il database sia pronto
echo -e "${YELLOW}⏳ Attesa che il database sia pronto...${NC}"
MAX_TRIES=30
TRIES=0

until psql "$DATABASE_URL" -c '\l' > /dev/null 2>&1; do
  TRIES=$((TRIES+1))
  if [ $TRIES -eq $MAX_TRIES ]; then
    echo -e "${RED}✗ Timeout: impossibile connettersi al database${NC}"
    exit 1
  fi
  echo -e "${YELLOW}  Tentativo $TRIES/$MAX_TRIES...${NC}"
  sleep 2
done

echo -e "${GREEN}✓ Database pronto${NC}"

# Esegue le migrazioni di Alembic
echo -e "${GREEN}📦 Applicazione migrazioni database...${NC}"
if alembic upgrade head; then
  echo -e "${GREEN}✓ Migrazioni applicate con successo${NC}"
else
  echo -e "${RED}✗ Errore durante l'applicazione delle migrazioni${NC}"
  exit 1
fi

# Avvia l'applicazione Flask
echo -e "${GREEN}🚀 Avvio server Flask sulla porta ${APP_PORT:-5000}${NC}"
exec python -m flask run --host=0.0.0.0 --port=${APP_PORT:-5000}