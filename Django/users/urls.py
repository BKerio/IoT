from django.urls import path

from . import views

urlpatterns = [
    path("users/register", views.register, name="user_register"),
    path("users/me", views.me, name="user_me"),
    path("login", views.login, name="user_login"),
]
