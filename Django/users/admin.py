from django.contrib import admin

from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "full_name",
        "email",
        "telephone",
        "created_at",
    )
    search_fields = ("full_name", "email", "telephone")
    readonly_fields = ("password_hash", "auth_token", "created_at")
