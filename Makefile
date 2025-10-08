# Makefile for managing Flask application with Docker and Alembic

# Variables
COMPOSE = docker compose
WEB_SERVICE = web
DB_SERVICE = db
PGADMIN_SERVICE = pgadmin
APP_DIR = app
MIGRATIONS_DIR = $(APP_DIR)/migrations
VERSIONS_DIR = $(MIGRATIONS_DIR)/versions
ENV_FILE = .env
BACKUP_DIR = ./backups

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Load environment variables if .env exists
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export
endif

# Auto-detect UID and GID if not set
ifndef UID
    UID := $(shell id -u)
endif
ifndef GID
    GID := $(shell id -g)
endif

export UID
export GID

.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "$(GREEN)Available commands:$(NC)"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## init: Initialize the project (create .env and migrations structure)
init: init-env init-migrations init-backup-dir fix-permissions
	@echo "$(GREEN)✓ Project initialized successfully!$(NC)"
	@echo "$(YELLOW)Remember to modify the .env file with your configurations$(NC)"
	@echo "$(BLUE)pgAdmin will be available at: http://localhost:$(PGADMIN_EXTERNAL_PORT)$(NC)"

## init-env: Create .env file from .env.example
init-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f .env.example ]; then \
			cp .env.example $(ENV_FILE); \
			sed -i "s/UID=1000/UID=$(UID)/" $(ENV_FILE); \
			sed -i "s/GID=1000/GID=$(GID)/" $(ENV_FILE); \
			echo "$(GREEN)✓ .env file created from .env.example$(NC)"; \
			echo "$(BLUE)  Detected UID=$(UID) GID=$(GID)$(NC)"; \
		else \
			echo "$(RED)✗ .env.example file not found$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)⚠ .env file already exists$(NC)"; \
	fi

## init-migrations: Initialize Alembic migrations directory
init-migrations:
	@if [ ! -d $(MIGRATIONS_DIR) ]; then \
		mkdir -p $(MIGRATIONS_DIR); \
		mkdir -p $(VERSIONS_DIR); \
		touch $(MIGRATIONS_DIR)/__init__.py; \
		echo "$(GREEN)✓ Migrations structure created$(NC)"; \
	else \
		if [ ! -d $(VERSIONS_DIR) ]; then \
			mkdir -p $(VERSIONS_DIR); \
			echo "$(GREEN)✓ Versions directory created$(NC)"; \
		fi; \
		if [ ! -f $(MIGRATIONS_DIR)/__init__.py ]; then \
			touch $(MIGRATIONS_DIR)/__init__.py; \
			echo "$(GREEN)✓ __init__.py file created$(NC)"; \
		fi; \
		echo "$(YELLOW)⚠ Migrations directory already exists$(NC)"; \
	fi

## init-backup-dir: Initialize backup directory
init-backup-dir:
	@if [ ! -d $(BACKUP_DIR) ]; then \
		mkdir -p $(BACKUP_DIR); \
		echo "$(GREEN)✓ Backup directory created$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Backup directory already exists$(NC)"; \
	fi

## build: Build Docker images
build:
	@echo "$(GREEN)Building Docker images...$(NC)"
	$(COMPOSE) build

## up: Start containers in background
up:
	@echo "$(GREEN)Starting containers...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Containers started$(NC)"
	@echo "$(BLUE)pgAdmin: http://localhost:$(PGADMIN_EXTERNAL_PORT)$(NC)"
	@make ps

## down: Stop and remove containers
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

## restart: Restart containers
restart: down up

## ps: Show container status
ps:
	@$(COMPOSE) ps

## logs: View web service logs
logs:
	$(COMPOSE) logs -f $(WEB_SERVICE)

## logs-db: View database logs
logs-db:
	$(COMPOSE) logs -f $(DB_SERVICE)

## logs-pgadmin: View pgAdmin logs
logs-pgadmin:
	$(COMPOSE) logs -f $(PGADMIN_SERVICE)

## logs-all: View all logs
logs-all:
	$(COMPOSE) logs -f

## shell: Open bash shell in web container
shell:
	@echo "$(GREEN)Opening shell in web container...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) bash

## shell-db: Open psql shell in database
shell-db:
	@echo "$(GREEN)Opening PostgreSQL shell...$(NC)"
	$(COMPOSE) exec $(DB_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

## migrate: Create a new migration (requires MSG="message")
migrate:
	@if [ -z "$(MSG)" ]; then \
		echo "$(RED)✗ Error: You must specify a message$(NC)"; \
		echo "$(YELLOW)Usage: make migrate MSG='migration description'$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d $(VERSIONS_DIR) ]; then \
		echo "$(YELLOW)⚠ Versions directory missing, creating...$(NC)"; \
		mkdir -p $(VERSIONS_DIR); \
	fi
	@echo "$(GREEN)Creating migration: $(MSG)$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic revision --autogenerate -m "$(MSG)"
	@echo "$(GREEN)✓ Migration created$(NC)"

## upgrade: Apply all pending migrations
upgrade:
	@echo "$(GREEN)Applying migrations...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic upgrade head
	@echo "$(GREEN)✓ Migrations applied$(NC)"

## downgrade: Rollback last migration
downgrade:
	@echo "$(YELLOW)Rolling back last migration...$(NC)"
	$(COMPOSE) exec $(WEB_SERVICE) alembic downgrade -1
	@echo "$(GREEN)✓ Rollback completed$(NC)"

## migrate-status: Check migrations status
migrate-status:
	@echo "$(GREEN)Current migration status:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic current

## migrate-history: Show migrations history
migrate-history:
	@echo "$(GREEN)Migrations history:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic history --verbose

## backup: Create database backup
backup:
	@echo "$(GREEN)Creating database backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	BACKUP_FILE="$(BACKUP_DIR)/backup_$${TIMESTAMP}.sql"; \
	$(COMPOSE) exec -T $(DB_SERVICE) pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) > $${BACKUP_FILE}; \
	if [ -f $${BACKUP_FILE} ]; then \
		gzip $${BACKUP_FILE}; \
		echo "$(GREEN)✓ Backup created: $${BACKUP_FILE}.gz$(NC)"; \
		echo "$(BLUE)  Size: $$(du -h $${BACKUP_FILE}.gz | cut -f1)$(NC)"; \
	else \
		echo "$(RED)✗ Backup failed$(NC)"; \
		exit 1; \
	fi

## restore: Restore database from backup (requires FILE=backup_file.sql.gz)
restore:
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)✗ Error: You must specify a backup file$(NC)"; \
		echo "$(YELLOW)Usage: make restore FILE=backups/backup_20231201_120000.sql.gz$(NC)"; \
		echo "$(BLUE)Available backups:$(NC)"; \
		ls -lh $(BACKUP_DIR)/*.sql.gz 2>/dev/null || echo "  No backups found"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "$(RED)✗ Error: Backup file not found: $(FILE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(RED)⚠ WARNING: This will overwrite the current database!$(NC)"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Restoring database from $(FILE)...$(NC)"
	@gunzip -c $(FILE) | $(COMPOSE) exec -T $(DB_SERVICE) psql -U $(POSTGRES_USER) $(POSTGRES_DB)
	@echo "$(GREEN)✓ Database restored$(NC)"

## backup-list: List all available backups
backup-list:
	@echo "$(GREEN)Available backups:$(NC)"
	@if [ -d $(BACKUP_DIR) ] && [ -n "$$(ls -A $(BACKUP_DIR)/*.sql.gz 2>/dev/null)" ]; then \
		ls -lh $(BACKUP_DIR)/*.sql.gz; \
	else \
		echo "$(YELLOW)  No backups found$(NC)"; \
	fi

## backup-clean: Remove old backups (keeps last BACKUP_RETENTION_DAYS days)
backup-clean:
	@echo "$(YELLOW)Cleaning old backups (keeping last $(BACKUP_RETENTION_DAYS) days)...$(NC)"
	@if [ -d $(BACKUP_DIR) ]; then \
		find $(BACKUP_DIR) -name "backup_*.sql.gz" -type f -mtime +$(BACKUP_RETENTION_DAYS) -delete; \
		echo "$(GREEN)✓ Old backups cleaned$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Backup directory not found$(NC)"; \
	fi

## db-reset: Complete database reset (WARNING: deletes all data!)
db-reset:
	@echo "$(RED)⚠ WARNING: This operation will delete all data!$(NC)"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Creating backup before reset...$(NC)"
	@make backup
	@echo "$(YELLOW)Resetting database...$(NC)"
	@$(COMPOSE) down -v
	@echo "$(GREEN)✓ Volumes removed$(NC)"
	@$(COMPOSE) up -d
	@echo "$(YELLOW)Waiting for database to be ready...$(NC)"
	@sleep 10
	@make upgrade
	@echo "$(GREEN)✓ Database reset completed$(NC)"

## fix-permissions: Fix directory permissions
fix-permissions:
	@echo "$(GREEN)Fixing permissions...$(NC)"
	@if [ -d $(APP_DIR)/migrations ]; then \
		sudo chown -R $(UID):$(GID) $(APP_DIR)/migrations 2>/dev/null || \
		echo "$(YELLOW)⚠ Could not change ownership (trying chmod only)$(NC)"; \
		chmod -R 755 $(APP_DIR)/migrations 2>/dev/null || \
		sudo chmod -R 755 $(APP_DIR)/migrations; \
	fi
	@if [ -d $(BACKUP_DIR) ]; then \
		sudo chown -R $(UID):$(GID) $(BACKUP_DIR) 2>/dev/null || true; \
		chmod -R 755 $(BACKUP_DIR) 2>/dev/null || \
		sudo chmod -R 755 $(BACKUP_DIR); \
	fi
	@echo "$(GREEN)✓ Permissions fixed$(NC)"

## pgadmin-open: Open pgAdmin in browser
pgadmin-open:
	@echo "$(BLUE)Opening pgAdmin...$(NC)"
	@echo "URL: http://localhost:$(PGADMIN_EXTERNAL_PORT)"
	@echo "Email: $(PGADMIN_EMAIL)"
	@echo "Password: $(PGADMIN_PASSWORD)"
	@echo ""
	@echo "$(YELLOW)To connect to the database:$(NC)"
	@echo "  Host: db"
	@echo "  Port: 5432"
	@echo "  Database: $(POSTGRES_DB)"
	@echo "  Username: $(POSTGRES_USER)"
	@echo "  Password: $(POSTGRES_PASSWORD)"

## test: Run tests (to be implemented)
test:
	@echo "$(YELLOW)Tests not yet implemented$(NC)"

## clean: Remove unused containers, images and volumes
clean:
	@echo "$(YELLOW)Cleaning containers, images and volumes...$(NC)"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

## clean-all: Complete cleanup including database data
clean-all:
	@echo "$(RED)⚠ WARNING: This will delete all data including backups!$(NC)"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)Removing all data...$(NC)"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@sudo rm -rf postgres_data 2>/dev/null || rm -rf postgres_data 2>/dev/null || true
	@sudo rm -rf $(BACKUP_DIR) 2>/dev/null || rm -rf $(BACKUP_DIR) 2>/dev/null || true
	@echo "$(GREEN)✓ Complete cleanup done$(NC)"

## dev: Start development environment
dev: up logs

## prod: Build and start in production mode
prod:
	@echo "$(GREEN)Starting in production mode...$(NC)"
	@export FLASK_ENV=production && $(COMPOSE) up -d --build
	@echo "$(GREEN)✓ Application in production$(NC)"

## status: Show complete system status
status:
	@echo "$(GREEN)=== System Status ===$(NC)"
	@echo ""
	@echo "$(BLUE)Containers:$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(BLUE)Migration Status:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic current 2>/dev/null || echo "  Not available"
	@echo ""
	@echo "$(BLUE)Disk Usage:$(NC)"
	@docker system df
	@echo ""
	@echo "$(BLUE)Recent Backups:$(NC)"
	@ls -lht $(BACKUP_DIR)/*.sql.gz 2>/dev/null | head -5 || echo "  No backups found"

.PHONY: help init init-env init-migrations init-backup-dir build up down restart ps \
        logs logs-db logs-pgadmin logs-all shell shell-db migrate upgrade downgrade \
        migrate-status migrate-history backup restore backup-list backup-clean \
        db-reset fix-permissions pgadmin-open test clean clean-all dev prod status