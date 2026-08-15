import os
from pathlib import Path
from dotenv import load_dotenv
import dj_database_url

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY is not set. Copy .env.example to .env and fill it in.")

DEBUG = os.getenv("DEBUG", "False") == "True"

ALLOWED_HOSTS = [h.strip() for h in os.getenv("ALLOWED_HOSTS", "*").split(",") if h.strip()]

# Shared secret the ESP32 sends in an X-Device-Key header when posting sensor
# readings, since it can't authenticate as an app user.
DEVICE_API_KEY = os.getenv("DEVICE_API_KEY", "")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    "users",
    "bins",
]

# REQUIRED FOR DJANGO ADMIN
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",

    "django.contrib.sessions.middleware.SessionMiddleware",

    "django.middleware.common.CommonMiddleware",

    "django.middleware.csrf.CsrfViewMiddleware",

    "django.contrib.auth.middleware.AuthenticationMiddleware",

    "django.contrib.messages.middleware.MessageMiddleware",

    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

# REQUIRED TEMPLATE ENGINE
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",

        "DIRS": [BASE_DIR / "templates"],

        "APP_DIRS": True,

        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",

                "django.template.context_processors.request",

                "django.contrib.auth.context_processors.auth",

                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set. Copy .env.example to .env and fill it in.")

# Supabase's pooler URL includes `pgbouncer`/`connection_limit` query params meant for
# Prisma-style clients; psycopg2 doesn't recognize them as connection options, so drop them
# before parsing and rely on CONN_MAX_AGE below instead.
_db_config = dj_database_url.parse(DATABASE_URL, conn_max_age=600, ssl_require=True)
_db_config["OPTIONS"] = {
    k: v for k, v in _db_config.get("OPTIONS", {}).items()
    if k not in ("pgbouncer", "connection_limit")
}

DATABASES = {"default": _db_config}

# If you're on Supabase's transaction-mode pooler (port 6543), it doesn't support
# persistent server-side connections or prepared statements — uncomment these:
# DATABASES["default"]["CONN_MAX_AGE"] = 0
# DATABASES["default"]["DISABLE_SERVER_SIDE_CURSORS"] = True

STATIC_URL = "static/"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"