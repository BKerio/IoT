from django.db import models

# Empty-bin distance from the ultrasonic sensor to the bottom of the bin, in
# cm. A reading equal to this means the bin is empty; a reading near 0 means
# it's full. Adjust to match the physical bin the sensor is mounted on.
BIN_HEIGHT_CM = 30.0


def distance_to_fill_percent(distance_cm, bin_height_cm=BIN_HEIGHT_CM):
    if bin_height_cm <= 0:
        return 0.0
    percent = ((bin_height_cm - distance_cm) / bin_height_cm) * 100
    return max(0.0, min(100.0, percent))


class SensorReading(models.Model):
    # Lets one Django backend serve more than one physical bin later without
    # a schema change; a single-bin setup can just leave this at its default.
    device_id = models.CharField(max_length=50, default="bin-1")
    distance_cm = models.FloatField()
    fill_percent = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.device_id}: {self.fill_percent:.0f}% ({self.created_at})"

    def save(self, *args, **kwargs):
        if self.fill_percent is None:
            self.fill_percent = distance_to_fill_percent(self.distance_cm)
        super().save(*args, **kwargs)
