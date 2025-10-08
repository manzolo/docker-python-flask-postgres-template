# ============================================================================
# Flask PostgreSQL Docker Template - Makefile
# ============================================================================

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
MAGENTA = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[1;37m
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

# ============================================================================
# 📚 HELP & DOCUMENTATION
# ============================================================================

## help: Show this help message
help:
	@echo ""
	@echo "$(WHITE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(WHITE)║        Flask PostgreSQL Template - Available Commands          ║$(NC)"
	@echo "$(WHITE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📦 Project Setup:$(NC)"
	@grep -E '^## (init|fix-permissions):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(BLUE)🐳 Docker Management:$(NC)"
	@grep -E '^## (build|up|down|restart|ps|status):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(GREEN)📋 Logs & Debugging:$(NC)"
	@grep -E '^## (logs|shell):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(MAGENTA)🔄 Database Migrations:$(NC)"
	@grep -E '^## (migrate|upgrade|downgrade|migrate-status|migrate-history|seed):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(YELLOW)💾 Backup & Restore:$(NC)"
	@grep -E '^## (backup|restore|backup-list|backup-clean):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(RED)🔧 Database Management:$(NC)"
	@grep -E '^## (db-reset|pgadmin-open):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(CYAN)🚀 Development & Production:$(NC)"
	@grep -E '^## (dev|prod|test):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""
	@echo "$(WHITE)🧹 Cleanup:$(NC)"
	@grep -E '^## (clean|clean-all):' $(MAKEFILE_LIST) | sed 's/##/  /' | column -t -s ':'
	@echo ""

# ============================================================================
# 📦 PROJECT SETUP
# ============================================================================

## init: Initialize the project (create .env and migrations structure)
init: init-env init-migrations init-backup-dir fix-permissions
	@echo ""
	@echo "$(WHITE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(WHITE)║               ✓ Project Initialized Successfully               ║$(NC)"
	@echo "$(WHITE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📝 Next steps:$(NC)"
	@echo "  1. Edit the .env file with your configurations"
	@echo "  2. Run: $(CYAN)make up$(NC) to start the application"
	@echo "  3. Run: $(CYAN)make seed$(NC) to populate with demo data"
	@echo ""
	@echo "$(BLUE)🌐 Access points:$(NC)"
	@echo "  • Flask App: $(WHITE)http://localhost:5000$(NC)"
	@echo "  • pgAdmin:   $(WHITE)http://localhost:$(PGADMIN_EXTERNAL_PORT)$(NC)"
	@echo ""

## init-env: Create .env file from .env.example
init-env:
	@echo "$(CYAN)→ Initializing environment...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f .env.example ]; then \
			cp .env.example $(ENV_FILE); \
			sed -i "s/UID=1000/UID=$(UID)/" $(ENV_FILE) 2>/dev/null || true; \
			sed -i "s/GID=1000/GID=$(GID)/" $(ENV_FILE) 2>/dev/null || true; \
			echo "$(GREEN)  ✓ .env file created from .env.example$(NC)"; \
			echo "$(BLUE)  ℹ Detected UID=$(UID) GID=$(GID)$(NC)"; \
		else \
			echo "$(RED)  ✗ .env.example file not found$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)  ⚠ .env file already exists$(NC)"; \
	fi

## init-migrations: Initialize Alembic migrations directory
init-migrations:
	@echo "$(CYAN)→ Initializing migrations...$(NC)"
	@if [ ! -d $(MIGRATIONS_DIR) ]; then \
		mkdir -p $(MIGRATIONS_DIR); \
		mkdir -p $(VERSIONS_DIR); \
		touch $(MIGRATIONS_DIR)/__init__.py; \
		echo "$(GREEN)  ✓ Migrations structure created$(NC)"; \
	else \
		if [ ! -d $(VERSIONS_DIR) ]; then \
			mkdir -p $(VERSIONS_DIR); \
			echo "$(GREEN)  ✓ Versions directory created$(NC)"; \
		fi; \
		if [ ! -f $(MIGRATIONS_DIR)/__init__.py ]; then \
			touch $(MIGRATIONS_DIR)/__init__.py; \
			echo "$(GREEN)  ✓ __init__.py file created$(NC)"; \
		fi; \
		echo "$(YELLOW)  ⚠ Migrations directory already exists$(NC)"; \
	fi

## init-backup-dir: Initialize backup directory
init-backup-dir:
	@echo "$(CYAN)→ Initializing backup directory...$(NC)"
	@if [ ! -d $(BACKUP_DIR) ]; then \
		mkdir -p $(BACKUP_DIR); \
		echo "$(GREEN)  ✓ Backup directory created$(NC)"; \
	else \
		echo "$(YELLOW)  ⚠ Backup directory already exists$(NC)"; \
	fi

## fix-permissions: Fix directory permissions
fix-permissions:
	@echo "$(CYAN)→ Fixing permissions...$(NC)"
	@if [ -d $(APP_DIR)/migrations ]; then \
		sudo chown -R $(UID):$(GID) $(APP_DIR)/migrations 2>/dev/null || \
		echo "$(YELLOW)  ⚠ Could not change ownership (trying chmod only)$(NC)"; \
		chmod -R 755 $(APP_DIR)/migrations 2>/dev/null || \
		sudo chmod -R 755 $(APP_DIR)/migrations; \
	fi
	@if [ -d $(BACKUP_DIR) ]; then \
		sudo chown -R $(UID):$(GID) $(BACKUP_DIR) 2>/dev/null || true; \
		chmod -R 755 $(BACKUP_DIR) 2>/dev/null || \
		sudo chmod -R 755 $(BACKUP_DIR); \
	fi
	@echo "$(GREEN)  ✓ Permissions fixed$(NC)"

# ============================================================================
# 🐳 DOCKER MANAGEMENT
# ============================================================================

## build: Build Docker images
build:
	@echo "$(BLUE)🔨 Building Docker images...$(NC)"
	@$(COMPOSE) build
	@echo "$(GREEN)✓ Build completed$(NC)"

## up: Start containers in background
up:
	@echo "$(BLUE)🚀 Starting containers...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)✓ Containers started$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 Services available at:$(NC)"
	@echo "  • Flask App: $(WHITE)http://localhost:5000$(NC)"
	@echo "  • pgAdmin:   $(WHITE)http://localhost:$(PGADMIN_EXTERNAL_PORT)$(NC)"
	@echo ""
	@make ps

## down: Stop and remove containers
down:
	@echo "$(YELLOW)⏹  Stopping containers...$(NC)"
	@$(COMPOSE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

## restart: Restart containers
restart:
	@echo "$(YELLOW)🔄 Restarting containers...$(NC)"
	@make down
	@make up

## ps: Show container status
ps:
	@echo "$(CYAN)📊 Container Status:$(NC)"
	@$(COMPOSE) ps

## status: Show complete system status
status:
	@echo ""
	@echo "$(WHITE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(WHITE)║                        System Status                           ║$(NC)"
	@echo "$(WHITE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🐳 Containers:$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(MAGENTA)🔄 Migration Status:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic current 2>/dev/null || echo "  $(YELLOW)⚠ Not available$(NC)"
	@echo ""
	@echo "$(BLUE)💿 Disk Usage:$(NC)"
	@docker system df
	@echo ""
	@echo "$(YELLOW)💾 Recent Backups:$(NC)"
	@ls -lht $(BACKUP_DIR)/*.sql.gz 2>/dev/null | head -5 || echo "  $(YELLOW)⚠ No backups found$(NC)"
	@echo ""

# ============================================================================
# 📋 LOGS & DEBUGGING
# ============================================================================

## logs: View web service logs
logs:
	@echo "$(GREEN)📋 Viewing web service logs (Ctrl+C to exit)...$(NC)"
	@$(COMPOSE) logs -f $(WEB_SERVICE)

## logs-db: View database logs
logs-db:
	@echo "$(GREEN)📋 Viewing database logs (Ctrl+C to exit)...$(NC)"
	@$(COMPOSE) logs -f $(DB_SERVICE)

## logs-pgadmin: View pgAdmin logs
logs-pgadmin:
	@echo "$(GREEN)📋 Viewing pgAdmin logs (Ctrl+C to exit)...$(NC)"
	@$(COMPOSE) logs -f $(PGADMIN_SERVICE)

## logs-all: View all logs
logs-all:
	@echo "$(GREEN)📋 Viewing all logs (Ctrl+C to exit)...$(NC)"
	@$(COMPOSE) logs -f

## shell: Open bash shell in web container
shell:
	@echo "$(CYAN)🐚 Opening shell in web container...$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) bash

## shell-db: Open psql shell in database
shell-db:
	@echo "$(CYAN)🐚 Opening PostgreSQL shell...$(NC)"
	@$(COMPOSE) exec $(DB_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# ============================================================================
# 🔄 DATABASE MIGRATIONS
# ============================================================================

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
	@echo "$(MAGENTA)🔄 Creating migration: $(MSG)$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic revision --autogenerate -m "$(MSG)"
	@echo "$(GREEN)✓ Migration created$(NC)"

## upgrade: Apply all pending migrations
upgrade:
	@echo "$(MAGENTA)🔄 Applying migrations...$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic upgrade head
	@echo "$(GREEN)✓ Migrations applied$(NC)"

## downgrade: Rollback last migration
downgrade:
	@echo "$(YELLOW)⏪ Rolling back last migration...$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic downgrade -1
	@echo "$(GREEN)✓ Rollback completed$(NC)"

## migrate-status: Check migrations status
migrate-status:
	@echo "$(MAGENTA)📊 Current migration status:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic current

## migrate-history: Show migrations history
migrate-history:
	@echo "$(MAGENTA)📜 Migrations history:$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) alembic history --verbose

## seed: Populate database with demo data
seed:
	@echo "$(GREEN)🌱 Seeding database with demo data...$(NC)"
	@$(COMPOSE) exec $(WEB_SERVICE) python -m app.seed
	@echo "$(GREEN)✓ Database seeded$(NC)"

# ============================================================================
# 💾 BACKUP & RESTORE
# ============================================================================

## backup: Create database backup
backup:
	@echo "$(YELLOW)💾 Creating database backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	BACKUP_FILE="$(BACKUP_DIR)/backup_$${TIMESTAMP}.sql"; \
	$(COMPOSE) exec -T $(DB_SERVICE) pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) > $${BACKUP_FILE}; \
	if [ -f $${BACKUP_FILE} ]; then \
		gzip $${BACKUP_FILE}; \
		echo "$(GREEN)✓ Backup created: $${BACKUP_FILE}.gz$(NC)"; \
		echo "$(BLUE)  📦 Size: $$(du -h $${BACKUP_FILE}.gz | cut -f1)$(NC)"; \
	else \
		echo "$(RED)✗ Backup failed$(NC)"; \
		exit 1; \
	fi

## restore: Restore database from backup (requires FILE=backup_file.sql.gz)
restore:
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)✗ Error: You must specify a backup file$(NC)"; \
		echo "$(YELLOW)Usage: make restore FILE=backups/backup_20231201_120000.sql.gz$(NC)"; \
		echo "$(BLUE)📋 Available backups:$(NC)"; \
		ls -lh $(BACKUP_DIR)/*.sql.gz 2>/dev/null || echo "  $(YELLOW)⚠ No backups found$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "$(RED)✗ Error: Backup file not found: $(FILE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(RED)⚠ WARNING: This will overwrite the current database!$(NC)"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)📥 Restoring database from $(FILE)...$(NC)"
	@gunzip -c $(FILE) | $(COMPOSE) exec -T $(DB_SERVICE) psql -U $(POSTGRES_USER) $(POSTGRES_DB)
	@echo "$(GREEN)✓ Database restored$(NC)"

## backup-list: List all available backups
backup-list:
	@echo "$(YELLOW)📋 Available backups:$(NC)"
	@if [ -d $(BACKUP_DIR) ] && [ -n "$$(ls -A $(BACKUP_DIR)/*.sql.gz 2>/dev/null)" ]; then \
		ls -lht $(BACKUP_DIR)/*.sql.gz; \
	else \
		echo "  $(YELLOW)⚠ No backups found$(NC)"; \
	fi

## backup-clean: Remove old backups (keeps last BACKUP_RETENTION_DAYS days)
backup-clean:
	@echo "$(YELLOW)🧹 Cleaning old backups (keeping last $(BACKUP_RETENTION_DAYS) days)...$(NC)"
	@if [ -d $(BACKUP_DIR) ]; then \
		find $(BACKUP_DIR) -name "backup_*.sql.gz" -type f -mtime +$(BACKUP_RETENTION_DAYS) -delete; \
		echo "$(GREEN)✓ Old backups cleaned$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Backup directory not found$(NC)"; \
	fi

# ============================================================================
# 🔧 DATABASE MANAGEMENT
# ============================================================================

## db-reset: Complete database reset (WARNING: deletes all data!)
db-reset:
	@echo ""
	@echo "$(RED)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(RED)║                         ⚠  WARNING  ⚠                          ║$(NC)"
	@echo "$(RED)║          This operation will delete all database data!         ║$(NC)"
	@echo "$(RED)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)💾 Creating backup before reset...$(NC)"
	@make backup
	@echo "$(YELLOW)🔄 Resetting database...$(NC)"
	@$(COMPOSE) down -v
	@echo "$(GREEN)  ✓ Volumes removed$(NC)"
	@$(COMPOSE) up -d
	@echo "$(YELLOW)⏳ Waiting for database to be ready...$(NC)"
	@sleep 10
	@make upgrade
	@echo "$(GREEN)✓ Database reset completed$(NC)"

## pgadmin-open: Show pgAdmin connection info
pgadmin-open:
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    pgAdmin Connection Info                     ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 pgAdmin Access:$(NC)"
	@echo "  URL:      $(WHITE)http://localhost:$(PGADMIN_EXTERNAL_PORT)$(NC)"
	@echo "  Email:    $(WHITE)$(PGADMIN_EMAIL)$(NC)"
	@echo "  Password: $(WHITE)$(PGADMIN_PASSWORD)$(NC)"
	@echo ""
	@echo "$(CYAN)🐘 Database Connection Settings:$(NC)"
	@echo "  Host:     $(WHITE)db$(NC)"
	@echo "  Port:     $(WHITE)5432$(NC)"
	@echo "  Database: $(WHITE)$(POSTGRES_DB)$(NC)"
	@echo "  Username: $(WHITE)$(POSTGRES_USER)$(NC)"
	@echo "  Password: $(WHITE)$(POSTGRES_PASSWORD)$(NC)"
	@echo ""

# ============================================================================
# 🚀 DEVELOPMENT & PRODUCTION
# ============================================================================

## dev: Start development environment
dev: up logs

## prod: Build and start in production mode
prod:
	@echo "$(GREEN)🚀 Starting in production mode...$(NC)"
	@export FLASK_ENV=production && $(COMPOSE) up -d --build
	@echo "$(GREEN)✓ Application in production$(NC)"

## test: Run tests (to be implemented)
test:
	@echo "$(YELLOW)⚠ Tests not yet implemented$(NC)"

# ============================================================================
# 🧹 CLEANUP
# ============================================================================

## clean: Remove unused containers, images and volumes
clean:
	@echo "$(YELLOW)🧹 Cleaning containers, images and volumes...$(NC)"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

## clean-all: Complete cleanup including database data
clean-all:
	@echo ""
	@echo "$(RED)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(RED)║                         ⚠  WARNING  ⚠                          ║$(NC)"
	@echo "$(RED)║     This will delete ALL data including backups forever!       ║$(NC)"
	@echo "$(RED)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "$(YELLOW)🧹 Removing all data...$(NC)"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@sudo rm -rf postgres_data 2>/dev/null || rm -rf postgres_data 2>/dev/null || true
	@sudo rm -rf $(BACKUP_DIR) 2>/dev/null || rm -rf $(BACKUP_DIR) 2>/dev/null || true
	@echo "$(GREEN)✓ Complete cleanup done$(NC)"

# ============================================================================

.PHONY: help init init-env init-migrations init-backup-dir build up down restart ps \
        logs logs-db logs-pgadmin logs-all shell shell-db migrate upgrade downgrade \
        migrate-status migrate-history seed backup restore backup-list backup-clean \
        db-reset fix-permissions pgadmin-open test clean clean-all dev prod status