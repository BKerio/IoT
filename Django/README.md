# 🚀 Django 

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)](https://www.python.org/)
[![Django](https://img.shields.io/badge/Django-6.0-092e20?logo=django&logoColor=white)](https://www.djangoproject.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Database-3ecf8e?logo=supabase&logoColor=white)](https://supabase.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A professionally structured Django application integrated with **Supabase PostgreSQL** for robust, scalable data management. This project serves as a solid foundation for building task-driven applications with modern cloud-native database features.

---

## ✨ Key Features

-   **Cloud-Native Database**: Seamless integration with Supabase (PostgreSQL).
-   **Security First**: Environment variable management using `python-dotenv`.
-   **SSL Encrypted**: Mandatory SSL for secure database communication.
-   **Task Engine**: Built-in Task model with title, description, and status tracking.
-   **Ready to Scale**: Clean directory structure following Django best practices.

---

## 🛠️ Tech Stack

-   **Backend**: [Django](https://www.djangoproject.com/)
-   **Database**: [PostgreSQL](https://www.postgresql.org/) (via [Supabase](https://supabase.com/))
-   **Environment**: [python-dotenv](https://github.com/theskumar/python-dotenv)
-   **Adapter**: [psycopg2-binary](https://pypi.org/project/psycopg2-binary/)
-   **DB URL parsing**: [dj-database-url](https://github.com/jazzband/dj-database-url) — configures `DATABASES` from a single `DATABASE_URL` string

---

## 🚀 Getting Started

### Prerequisites

-   Python 3.10 or higher
-   A Supabase account and project
-   `pip` (Python package manager)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/BKerio/django-supabase.git
    cd django_supabase
    ```

2.  **Set up Virtual Environment**
    ```bash
    python -m venv venv
    # Windows:
    venv\Scripts\activate
    # macOS/Linux:
    source venv/bin/activate
    ```

3.  **Install Dependencies**
    ```bash
    pip install -r requirements.txt
    ```

### Configuration

1.  **Environment Variables**
    Copy the template and fill in your own values:
    ```bash
    cp .env.example .env
    ```

2.  **Required variables** (`.env`)

    | Variable | Description |
    |---|---|
    | `DATABASE_URL` | Full connection string from Supabase Project Settings > Database > Connection string (URI). `6543` = transaction-mode pooler, `5432` = session-mode pooler — pick the one shown in your Supabase dashboard. |
    | `SECRET_KEY` | Django's cryptographic signing key. Generate one with `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`. |
    | `DEBUG` | `True` for local development, `False` in any deployed environment. |
    | `ALLOWED_HOSTS` | Comma-separated hostnames the app is allowed to serve, e.g. `localhost,127.0.0.1` locally, or your real domain in production. |

    All four are required — the app raises a clear startup error if `SECRET_KEY` or `DATABASE_URL` is missing.

    > If your `DATABASE_URL` is on the transaction-mode pooler (port `6543`), also uncomment the `CONN_MAX_AGE`/`DISABLE_SERVER_SIDE_CURSORS` lines in `config/settings.py` — pgbouncer in transaction mode doesn't support persistent connections or prepared statements.

---

## ⚙️ Development

### Database Migrations
Apply the initial migrations to set up your database schema:
```bash
python manage.py migrate
```

### Create Superuser
Access the Django Admin panel:
```bash
python manage.py createsuperuser
```

### Run Server
Start the development server:
```bash
python manage.py runserver
```
Visit `http://127.0.0.1:8000` to see your app in action!

---

## 📂 Project Structure

```text
django_supabase/
├── config/             # Project configuration (settings, URLs)
├── users/              # Users app
├── bins/               # Bins app
├── templates/           # HTML templates
├── manage.py           # Django management script
├── requirements.txt     # Python dependencies
├── .env                # Local secrets (ignored by git)
└── .env.example        # Template for environment variables
```

---

## 🔒 Security

> [!IMPORTANT]
> Never commit your `.env` file to version control. This project includes a `.gitignore` to prevent secret leakage. Always use `SECRET_KEY` and database credentials via environment variables in production.
>
> If a database password or secret key is ever shared outside `.env` (chat, a ticket, a public repo, etc.), treat it as compromised and rotate it immediately in Supabase Project Settings > Database, even if the exposure was brief.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.