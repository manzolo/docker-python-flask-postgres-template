# Flask Docker Template

Template base per applicazioni Flask con Docker, PostgreSQL e Alembic.

## Struttura del Progetto

```
my-flask-app/
├── app/
│   ├── __init__.py          # Factory dell'applicazione
│   ├── models.py            # Modelli SQLAlchemy
│   ├── routes.py            # Routes e blueprints
│   └── config.py            # Configurazioni
├── migrations/              # Migrations Alembic (generata automaticamente)
├── .env                     # Variabili d'ambiente (da creare)
├── .env.example             # Esempio di variabili d'ambiente
├── .gitignore              # File da ignorare in Git
├── docker-compose.yml      # Configurazione Docker Compose
├── Dockerfile              # Dockerfile per l'app
├── requirements.txt        # Dipendenze Python
├── run.py                  # Entry point dell'applicazione
└── README.md               # Questo file
```

## Setup Iniziale

### 1. Copia il template
```bash
cp -r flask-template my-new-project
cd my-new-project
```

### 2. Configura le variabili d'ambiente
```bash
cp .env.example .env
# Modifica .env con le tue configurazioni
```

### 3. Avvia i container Docker
```bash
docker-compose up -d
```

### 4. Inizializza il database con Alembic

**Prima migrazione:**
```bash
docker-compose exec web flask db init
docker-compose exec web flask db migrate -m "Initial migration"
docker-compose exec web flask db upgrade
```

**Migrazioni successive:**
```bash
# Dopo aver modificato i modelli
docker-compose exec web flask db migrate -m "Descrizione delle modifiche"
docker-compose exec web flask db upgrade
```

## Comandi Utili

### Docker
```bash
# Avvia i container
docker-compose up -d

# Ferma i container
docker-compose down

# Visualizza i log
docker-compose logs -f web

# Ricostruisci i container
docker-compose up -d --build

# Accedi alla shell del container
docker-compose exec web bash
```

### Database
```bash
# Accedi a PostgreSQL
docker-compose exec db psql -U flask_user -d flask_db

# Backup del database
docker-compose exec db pg_dump -U flask_user flask_db > backup.sql

# Restore del database
docker-compose exec -T db psql -U flask_user flask_db < backup.sql
```

### Flask Shell
```bash
# Apri la shell Flask (con accesso a db, User, Post)
docker-compose exec web flask shell
```

### Alembic
```bash
# Crea una nuova migrazione
docker-compose exec web flask db migrate -m "Messaggio"

# Applica le migrazioni
docker-compose exec web flask db upgrade

# Rollback ultima migrazione
docker-compose exec web flask db downgrade

# Visualizza lo stato delle migrazioni
docker-compose exec web flask db current

# Visualizza la cronologia delle migrazioni
docker-compose exec web flask db history
```

## API Endpoints

### Health Check
- `GET /health` - Verifica lo stato dell'applicazione

### Users
- `GET /api/users` - Ottieni tutti gli utenti
- `GET /api/users/<id>` - Ottieni un utente specifico
- `POST /api/users` - Crea un nuovo utente
- `DELETE /api/users/<id>` - Elimina un utente

### Posts
- `GET /api/posts` - Ottieni tutti i post
- `POST /api/posts` - Crea un nuovo post
- `GET /api/users/<id>/posts` - Ottieni tutti i post di un utente

## Esempi di Richieste

### Creare un utente
```bash
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"username": "mario", "email": "mario@example.com"}'
```

### Creare un post
```bash
curl -X POST http://localhost:5000/api/posts \
  -H "Content-Type: application/json" \
  -d '{"title": "Primo post", "content": "Contenuto del post", "user_id": 1}'
```

### Ottenere tutti gli utenti
```bash
curl http://localhost:5000/api/users
```

## Sviluppo

L'applicazione è configurata con hot-reload in modalità development. Modifica i file nel tuo editor e i cambiamenti saranno applicati automaticamente.

## Testing

Per eseguire i test:
```bash
docker-compose exec web python -m pytest
```

## Produzione

Per il deploy in produzione:

1. Modifica `docker-compose.yml` per rimuovere `--reload` da gunicorn
2. Imposta `FLASK_ENV=production` nel file `.env`
3. Cambia le password di default
4. Configura un reverse proxy (nginx/traefik)
5. Abilita HTTPS

## Note

- La porta 5000 è esposta per l'app Flask
- La porta 5432 è esposta per PostgreSQL
- I dati del database sono persistiti in un volume Docker
- Le migrations sono gestite con Flask-Migrate (wrapper di Alembic)