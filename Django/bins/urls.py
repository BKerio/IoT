from django.urls import path

from . import views

urlpatterns = [
    path("bins/readings", views.ingest_reading, name="bin_ingest_reading"),
    path("bins/latest", views.latest_reading, name="bin_latest_reading"),
]
