from django.contrib import admin

from .models import SensorReading


@admin.register(SensorReading)
class SensorReadingAdmin(admin.ModelAdmin):
    list_display = ("device_id", "distance_cm", "fill_percent", "created_at")
    search_fields = ("device_id",)
    readonly_fields = ("fill_percent", "created_at")
