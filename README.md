# Flask App con Docker e Alembic

Template per un'applicazione Flask con PostgreSQL, Docker e Alembic per la gestione delle migrazioni.

## 🚀 Quick Start

### Inizializzazione del progetto

```bash
# 1. Inizializza il progetto (crea .env e directory migrations)
make init

# 2. Modifica il file .env con le tue configurazioni

# 3. Costruisci e avvia i container
make build
make up

# 4. Crea la prima migrazione
make migrate MSG="initial migration"

# 5. Applica le migrazioni
make upgrade
```

### Comandi principali

```bash
make help              # Mostra tutti i comandi disponibili
make dev               # Avvia in modalità sviluppo con log
make ps                # Mostra lo stato dei container
make logs              # Visualizza i log dell'applicazione
make shell             # Apri una shell nel container
make restart           # Riavvia i container
make down              # Ferma i container
```

## 📦 Gestione Database e Migrazioni

### Creare una nuova migrazione

```bash
# Dopo aver modificato i modelli in app/models.py
make migrate MSG="aggiungi campo email a User"
```

### Applicare le migrazioni

```bash
make upgrade
```

### Rollback di una migrazione

```bash
make downgrade
```

### Verificare lo stato delle migrazioni

```bash
make migrate-status      # Stato corrente
make migrate-history     # Cronologia completa
```

### Accedere al database

```bash
make shell-db           # Apri shell PostgreSQL
```

### Reset completo del database (⚠️ ATTENZIONE!)

```bash
make db-reset           # Cancella tutto e ricrea
```

## 📁 Struttura del progetto

```
.
├── app/
│   ├── __init__.py           # Inizializzazione Flask app
│   ├── models.py             # Modelli SQLAlchemy
│   ├── routes.py             # Routes dell'applicazione
│   └── migrations/           # Migrazioni Alembic
│       ├── env.py            # Configurazione Alembic
│       ├── script.py.mako    # Template per nuove migrazioni
│       └── versions/         # File di migrazione
├── docker-compose.yml        # Configurazione Docker
├── Dockerfile                # Immagine Docker
├── entrypoint.sh            # Script di avvio
├── requirements.txt         # Dipendenze Python
├── alembic.ini             # Configurazione Alembic
├── Makefile                # Comandi di gestione
├── .env                    # Variabili d'ambiente (non committare!)
└── .env.example           # Template variabili d'ambiente
```

## 🔧 Configurazione

### Variabili d'ambiente (.env)

```bash
# Flask
FLASK_ENV=development
SECRET_KEY=your-secret-key
APP_PORT=5000

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=myapp_db
POSTGRES_PORT=5432

# Database URL
DATABASE_URL=postgresql://postgres:postgres@db:5432/myapp_db
```

## 📝 Workflow di sviluppo tipico

1. **Modifica i modelli** in `app/models.py`
2. **Crea una migrazione**: `make migrate MSG="descrizione"`
3. **Applica la migrazione**: `make upgrade`
4. **Testa le modifiche**: visita http://localhost:5000

## 🛠️ Troubleshooting

### I container non si avviano

```bash
# Controlla i log
make logs-all

# Ricostruisci le immagini
make clean
make build
make up
```

### Problemi con le migrazioni

```bash
# Verifica lo stato
make migrate-status

# Se necessario, reset completo
make db-reset
```

### Accesso al database negato

Verifica che le credenziali in `.env` siano corrette e che il container del database sia in esecuzione (`make ps`).

## 🧹 Pulizia

```bash
make clean          # Rimuove container e immagini
make clean-all      # Rimuove anche i dati del database
```

## 📚 Risorse utili

- [Flask Documentation](https://flask.palletsprojects.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [Docker Documentation](https://docs.docker.com/)
