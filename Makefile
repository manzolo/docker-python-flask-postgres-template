# Makefile per gestire l'applicazione Flask con Docker e Alembic

# Variabili
COMPOSE = docker compose
WEB_SERVICE = web
DB_SERVICE = db
APP_DIR = app
MIGRATIONS_DIR = $(APP_DIR)/migrations
VERSIONS_DIR = $(MIGRATIONS_DIR)/versions
ENV_FILE = .env

# Colori per output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Carica le variabili d'ambiente se il file .env esiste
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export
endif

.DEFAULT_GOAL := help

## help: Mostra questo messaggio di aiuto
help:
	@echo "$(GREEN)Comandi disponibili:$(NC)"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## init: Inizializza il progetto (crea .env e struttura migrations)
init: init-env init-migrations
	@echo "$(GREEN)✓ Progetto inizializzato con successo!$(NC)"
	@echo "$(YELLOW)Ricorda di modificare il file .env con le tue configurazioni$(NC)"

## init-env: Crea il file .env da .env.example
init-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f .env.example ]; then \
			cp .env.example $(ENV_FILE); \
			echo "$(GREEN)✓ File .env creato da .env.example$(NC)"; \
		else \
			echo "$(RED)✗ File .env.example non trovato$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)⚠ File .env già esistente$(NC)"; \
	fi

## init-migrations: Inizializza la directory delle migrazioni Alembic
init-migrations:
	@if [ ! -d $(MIGRATIONS_DIR) ]; then \
		mkdir -p $(MIGRATIONS_DIR); \
		mkdir -p $(VERSIONS_DIR); \
		touch $(MIGRATIONS_DIR)/__init__.py; \
		echo "$(GREEN)✓ Struttura migrations creata$(NC)"; \
	else \
		if [ ! -d $(VERSIONS_DIR) ]; then \
			mkdir -p $(VERSIONS_DIR); \
			echo "$(GREEN)✓ Directory versions creata$(NC)"; \
		fi; \
		if [ ! -f $(MIGRATIONS_DIR)/__init__.py ]; then \
			touch $(MIGRATIONS_DIR)/__init__.py; \
			echo "$(GREEN)✓ File __init__.py creato$(NC)"; \
		fi; \
		echo "$(YELLOW)⚠ Directory migrations già esistente$(NC)"; \
	fi

## build: Costruisce le immagini Docker
build:
	@echo "$(GREEN)Costruzione delle immagini Docker...$(NC)"
	$(COMPOSE) build

## up: Avvia i container in background
up:
	@echo "$(GREEN)Avvio dei container...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Container avviati$(NC)"
	@make ps

## down: Ferma e rimuove i container
down:
	@echo "$(YELLOW)Arresto dei container...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✓ Container fermati$(NC)"

## restart: Riavvia i container
restart: down up

## ps: Mostra lo stato dei container
ps:
	@$(COMPOSE) ps

## logs: Visualizza i log del servizio web
logs:
	$(COMPOSE) logs -f $(WEB_SERVICE)

## logs-db: Visualizza i log del database
logs-db:
	$(COMPOSE) logs -f $(DB_SERVICE)

## logs-all: Visualizza tutti i log
logs-all:
	$(COMPOSE) logs -f

## shell: Apre una shell bash nel container web
shell:
	@echo "$(GREEN)Apertura shell nel container web...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bash

## shell-db: Apre una shell psql nel database
shell-db:
	@echo "$(GREEN)Apertura shell PostgreSQL...$(NC)"
	$(COMPOSE) exec $(DB_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

## migrate: Crea una nuova migrazione (richiede MSG="messaggio")
migrate:
	@if [ -z "$(MSG)" ]; then \
		echo "$(RED)✗ Errore: Devi specificare un messaggio$(NC)"; \
		echo "$(YELLOW)Uso: make migrate MSG='descrizione migrazione'$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d $(VERSIONS_DIR) ]; then \
		echo "$(YELLOW)⚠ Directory versions mancante, creazione in corso...$(NC)"; \
		mkdir -p $(VERSIONS_DIR); \
	fi
	@echo "$(GREEN)Creazione migrazione: $(MSG)$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic revision --autogenerate -m "$(MSG)"
	@echo "$(GREEN)✓ Migrazione creata$(NC)"

## upgrade: Applica tutte le migrazioni pendenti
upgrade:
	@echo "$(GREEN)Applicazione migrazioni...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic upgrade head
	@echo "$(GREEN)✓ Migrazioni applicate$(NC)"

## downgrade: Rollback dell'ultima migrazione
downgrade:
	@echo "$(YELLOW)Rollback dell'ultima migrazione...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic downgrade -1
	@echo "$(GREEN)✓ Rollback completato$(NC)"

## migrate-status: Verifica lo stato delle migrazioni
migrate-status:
	@echo "$(GREEN)Stato corrente delle migrazioni:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic current

## migrate-history: Mostra la cronologia delle migrazioni
migrate-history:
	@echo "$(GREEN)Cronologia delle migrazioni:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic history --verbose

## db-reset: Reset completo del database (ATTENZIONE: cancella tutti i dati!)
db-reset:
	@echo "$(RED)⚠ ATTENZIONE: Questa operazione cancellerà tutti i dati!$(NC)"
	@echo "Sei sicuro? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Reset del database...$(NC)"
	@$(COMPOSE) down -v
	@rm -rf postgres_data
	@$(COMPOSE) up -d
	@sleep 5
	@make upgrade
	@echo "$(GREEN)✓ Database resettato$(NC)"

## test: Esegue i test (da implementare)
test:
	@echo "$(YELLOW)Test non ancora implementati$(NC)"

## clean: Rimuove container, immagini e volumi non utilizzati
clean:
	@echo "$(YELLOW)Pulizia di container, immagini e volumi...$(NC)"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "$(GREEN)✓ Pulizia completata$(NC)"

## clean-all: Pulizia completa inclusi i dati del database
clean-all: clean
	@echo "$(YELLOW)Rimozione dati del database...$(NC)"
	@rm -rf postgres_data
	@echo "$(GREEN)✓ Pulizia completa$(NC)"

## dev: Avvia l'ambiente di sviluppo
dev: up logs

## prod: Costruisce e avvia in modalità produzione
prod:
	@echo "$(GREEN)Avvio in modalità produzione...$(NC)"
	@export FLASK_ENV=production && $(COMPOSE) up -d --build
	@echo "$(GREEN)✓ Applicazione in produzione$(NC)"

## fix-permissions: Corregge i permessi delle directory (utile se hai problemi)
fix-permissions:
	@echo "$(GREEN)Correzione permessi...$(NC)"
	@chmod -R 755 $(APP_DIR)/migrations
	@echo "$(GREEN)✓ Permessi corretti$(NC)"

.PHONY: help init init-env init-migrations build up down restart ps logs logs-db logs-all \
        shell shell-db migrate upgrade downgrade migrate-status migrate-history \
        db-reset test clean clean-all dev prod fix-permissions