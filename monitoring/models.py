from django.db import models
from django.utils import timezone


class PhaseInformation(models.Model):
    """Per-area feeder phase reading (the old `Timestamp` column is recorded_at)."""

    phase_id = models.BigAutoField(primary_key=True)
    area = models.ForeignKey(
        "areas.Area",
        on_delete=models.CASCADE,    # child record of an area
        related_name="phase_information",
    )
    phase_name = models.CharField(max_length=50)
    reading_value = models.FloatField(null=True, blank=True)
    shift_status = models.CharField(max_length=50, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "phase_information"
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"{self.phase_name} @ {self.area}"


class VoltageReading(models.Model):
    """Voltage sample for an area (the old `Timestamp` column is recorded_at)."""

    STATUS_CHOICES = [
        ("normal", "Normal"),
        ("low", "Low"),
        ("high", "High"),
    ]

    reading_id = models.BigAutoField(primary_key=True)
    area = models.ForeignKey(
        "areas.Area",
        on_delete=models.CASCADE,    # child record of an area
        related_name="voltage_readings",
    )
    voltage_value = models.FloatField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES)
    recorded_at = models.DateTimeField(default=timezone.now)
    source_sensor = models.CharField(max_length=100, blank=True)

    class Meta:
        db_table = "voltage_readings"
        constraints = [
            models.CheckConstraint(
                name="chk_voltage_readings_status",
                condition=models.Q(status__in=["normal", "low", "high"]),
            ),
        ]
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"{self.voltage_value} V [{self.status}] @ {self.area}"


class OutageReport(models.Model):
    """A user-submitted outage / quality-of-supply report."""

    report_id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,    # child record of a user
        related_name="outage_reports",
    )
    area = models.ForeignKey(
        "areas.Area",
        on_delete=models.CASCADE,    # child record of an area
        related_name="outage_reports",
    )
    reported_at = models.DateTimeField(default=timezone.now)
    issue_type = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    is_verified = models.BooleanField(default=False)

    class Meta:
        db_table = "outage_reports"
        ordering = ["-reported_at"]

    def __str__(self):
        return f"{self.issue_type or 'report'} @ {self.area} ({self.reported_at:%Y-%m-%d})"


class AdminLog(models.Model):
    """Audit trail of administrative actions (readable / writable by admins only)."""

    log_id = models.BigAutoField(primary_key=True)
    admin = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,    # child record of a user
        related_name="admin_logs",
    )
    action_performed = models.CharField(max_length=255)
    target_table = models.CharField(max_length=100, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "admin_logs"
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"{self.admin} -> {self.action_performed}"
