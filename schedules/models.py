from django.db import models


class Schedule(models.Model):
    """
    A load-shedding window for an area.

    The old `Date` column is schedule_date; start_time / end_time are local
    wall-clock times on that date (check enforced: end_time > start_time).
    """

    STATUS_CHOICES = [
        ("scheduled", "Scheduled"),
        ("active", "Active"),
        ("completed", "Completed"),
        ("cancelled", "Cancelled"),
    ]
    RECURRENCE_CHOICES = [
        ("none", "None"),
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly"),
    ]

    schedule_id = models.BigAutoField(primary_key=True)
    area = models.ForeignKey(
        "areas.Area",
        on_delete=models.CASCADE,    # child record of an area
        related_name="schedules",
    )
    created_by_admin = models.ForeignKey(
        "users.User",
        on_delete=models.SET_NULL,   # optional link: schedule survives admin removal
        null=True,
        blank=True,
        related_name="created_schedules",
    )
    schedule_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    duration_minutes = models.IntegerField(null=True, blank=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES)
    recurrence = models.CharField(max_length=10, choices=RECURRENCE_CHOICES)

    class Meta:
        db_table = "schedules"
        constraints = [
            models.CheckConstraint(
                name="chk_schedules_status",
                condition=models.Q(status__in=["scheduled", "active", "completed", "cancelled"]),
            ),
            models.CheckConstraint(
                name="chk_schedules_recurrence",
                condition=models.Q(recurrence__in=["none", "daily", "weekly", "monthly"]),
            ),
            models.CheckConstraint(
                name="chk_schedules_time_order",
                condition=models.Q(end_time__gt=models.F("start_time")),
            ),
        ]
        ordering = ["schedule_date", "start_time"]

    def __str__(self):
        return (
            f"{self.area} {self.schedule_date} "
            f"{self.start_time:%H:%M}-{self.end_time:%H:%M} ({self.status})"
        )
