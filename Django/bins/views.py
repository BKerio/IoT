import json

from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models import SensorReading


def _json_body(request):
    try:
        return json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return {}


def _reading_dict(reading):
    return {
        "device_id": reading.device_id,
        "distance_cm": reading.distance_cm,
        "fill_percent": round(reading.fill_percent, 1),
        "created_at": reading.created_at.isoformat(),
    }


@csrf_exempt
@require_http_methods(["POST"])
def ingest_reading(request):
    # The ESP32 can't log in as a user, so it authenticates with a shared
    # secret instead. Set DEVICE_API_KEY in .env and hardcode the same value
    # in the firmware.
    device_key = request.headers.get("X-Device-Key", "")
    if not settings.DEVICE_API_KEY or device_key != settings.DEVICE_API_KEY:
        return JsonResponse({"status": 401, "message": "Invalid device key."}, status=401)

    data = _json_body(request)
    device_id = (data.get("device_id") or "bin-1").strip()
    distance_cm = data.get("distance_cm")

    if distance_cm is None:
        return JsonResponse(
            {"status": 422, "message": "distance_cm is required."}, status=422
        )

    try:
        distance_cm = float(distance_cm)
    except (TypeError, ValueError):
        return JsonResponse(
            {"status": 422, "message": "distance_cm must be a number."}, status=422
        )

    reading = SensorReading(device_id=device_id, distance_cm=distance_cm)
    reading.save()

    return JsonResponse(
        {"status": 200, "message": "Reading stored.", "reading": _reading_dict(reading)}
    )


@require_http_methods(["GET"])
def latest_reading(request):
    device_id = request.GET.get("device_id", "bin-1")
    reading = SensorReading.objects.filter(device_id=device_id).first()

    if reading is None:
        return JsonResponse({"status": 404, "message": "No readings yet."}, status=404)

    return JsonResponse({"status": 200, "reading": _reading_dict(reading)})
