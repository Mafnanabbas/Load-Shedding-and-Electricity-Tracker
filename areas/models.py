from django.db import models


class Substation(models.Model):
    """Primary grid substation feeding one or more load-shedding areas."""

    substation_id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=200)
    location = models.CharField(max_length=255, blank=True)
    capacity_mw = models.FloatField(null=True, blank=True)

    class Meta:
        db_table = "substations"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Area(models.Model):
    """A locality (feeder / zone) that load shedding is scheduled for."""

    area_id = models.BigAutoField(primary_key=True)
    substation = models.ForeignKey(
        Substation,
        on_delete=models.SET_NULL,   # optional link: area survives substation removal
        null=True,
        blank=True,
        related_name="areas",
    )
    area_name = models.CharField(max_length=200)
    city = models.CharField(max_length=100, blank=True)
    zip_code = models.CharField(max_length=20, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    description = models.TextField(blank=True)

    class Meta:
        db_table = "areas"
        ordering = ["area_name"]

    def __str__(self):
        return self.area_name
