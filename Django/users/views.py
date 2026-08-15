import json

from django.db import IntegrityError
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models import User


def _json_body(request):
    try:
        return json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return {}


def _user_public_dict(user):
    return {
        "id": user.id,
        "full_name": user.full_name,
        "name": user.full_name,
        "email": user.email,
        "telephone": user.telephone,
    }


def _authenticate(request):
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    token = auth_header[len("Bearer ") :].strip()
    if not token:
        return None
    return User.objects.filter(auth_token=token).first()


@csrf_exempt
@require_http_methods(["POST"])
def register(request):
    data = _json_body(request)

    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    telephone = (data.get("telephone") or "").strip()
    password = data.get("password") or ""

    errors = {}
    if not full_name:
        errors["full_name"] = "Full name is required."
    if not email:
        errors["email"] = "Email is required."
    if not telephone:
        errors["telephone"] = "Telephone is required."
    if not password:
        errors["password"] = "Password is required."
    elif len(password) < 6:
        errors["password"] = "Password must be at least 6 characters."

    if not errors and User.objects.filter(email__iexact=email).exists():
        errors["email"] = "An account with this email already exists."
    if not errors and User.objects.filter(telephone=telephone).exists():
        errors["telephone"] = "An account with this phone number already exists."

    if errors:
        # First error message doubles as the top-level message the app shows in a toast.
        return JsonResponse(
            {"status": 422, "message": next(iter(errors.values())), "errors": errors},
            status=422,
        )

    user = User(full_name=full_name, email=email, telephone=telephone)
    user.set_password(password)
    try:
        user.save()
    except IntegrityError:
        return JsonResponse(
            {
                "status": 422,
                "message": "An account with this email or phone number already exists.",
            },
            status=422,
        )

    return JsonResponse(
        {
            "status": 200,
            "message": "Registration successful.",
            "user": _user_public_dict(user),
        }
    )


@csrf_exempt
@require_http_methods(["POST"])
def login(request):
    data = _json_body(request)
    identifier = (data.get("identifier") or "").strip()
    password = data.get("password") or ""

    if not identifier or not password:
        return JsonResponse(
            {"status": 422, "message": "Please enter both identifier and password."},
            status=422,
        )

    user = (
        User.objects.filter(email__iexact=identifier).first()
        or User.objects.filter(telephone=identifier).first()
    )

    if user is None or not user.check_password(password):
        return JsonResponse({"status": 401, "message": "Invalid credentials."}, status=401)

    user.generate_token()
    user.save(update_fields=["auth_token"])

    return JsonResponse(
        {
            "status": 200,
            "message": "Login successful.",
            "token": user.auth_token,
            "user": {
                "id": user.id,
                "name": user.full_name,
                "email": user.email,
            },
        }
    )


@csrf_exempt
@require_http_methods(["GET"])
def me(request):
    user = _authenticate(request)
    if user is None:
        return JsonResponse({"status": 401, "message": "Unauthorized."}, status=401)

    return JsonResponse({"status": 200, "user": _user_public_dict(user)})
