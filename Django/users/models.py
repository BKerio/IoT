import secrets

from django.contrib.auth.hashers import check_password, make_password
from django.db import models


class User(models.Model):
    full_name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    telephone = models.CharField(max_length=20, unique=True)
    password_hash = models.CharField(max_length=255)

    # Simple bearer token, reissued on every successful login.
    auth_token = models.CharField(max_length=64, unique=True, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.full_name} <{self.email}>"

    def set_password(self, raw_password):
        self.password_hash = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password_hash)

    def generate_token(self):
        self.auth_token = secrets.token_hex(32)
        return self.auth_token
