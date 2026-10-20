from django.db import models
from django.utils import timezone


class User(models.Model):
    """
    Application user, linked to Supabase Auth.

    Authentication is handled by Supabase Auth (JWT): `auth_id` holds the
    auth.users.id of the signed-in identity. The table also keeps a local
    password_hash for legacy / offline credentials.

    Deliberately NOT a subclass of AbstractUser: the database schema defines
    its own columns (no username / is_staff / date_joined).
    """

    ROLE_CONSUMER = "consumer"
    ROLE_ADMIN = "admin"
    ROLE_CHOICES = [
        (ROLE_CONSUMER, "Consumer"),
        (ROLE_ADMIN, "Admin"),
    ]

    user_id = models.BigAutoField(primary_key=True)
    area = models.ForeignKey(
        "areas.Area",
        on_delete=models.CASCADE,    # a user belongs to an area
        related_name="users",
    )
    name = models.CharField(max_length=150)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=30, blank=True)
    password_hash = models.CharField(max_length=255)
    role = models.CharField(
        max_length=10,
        choices=ROLE_CHOICES,
        default=ROLE_CONSUMER,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    # No ForeignKey here: auth.users lives in the Supabase `auth` schema, which
    # Django has no model for. UNIQUE + nullable matches the SQL definition.
    auth_id = models.UUIDField(
        unique=True,
        null=True,
        blank=True,
        help_text="auth.users.id of the Supabase Auth identity",
    )

    class Meta:
        db_table = "users"
        constraints = [
            models.CheckConstraint(
                name="chk_users_role",
                condition=models.Q(role__in=["consumer", "admin"]),
            ),
        ]
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.role})"

    @property
    def is_admin(self):
        return self.role == self.ROLE_ADMIN


class Appliance(models.Model):
    """An owned appliance with the voltage band it can tolerate."""

    appliance_id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,    # child record of a user
        related_name="appliances",
    )
    appliance_type = models.CharField(max_length=100)
    max_voltage_tolerance = models.FloatField()
    min_voltage_tolerance = models.FloatField()

    class Meta:
        db_table = "appliances"
        constraints = [
            models.CheckConstraint(
                name="chk_appliances_voltage_tolerance",
                condition=models.Q(min_voltage_tolerance__lt=models.F("max_voltage_tolerance")),
            ),
        ]
        ordering = ["appliance_type"]

    def __str__(self):
        return f"{self.appliance_type} ({self.user})"


class Alert(models.Model):
    """A message pushed / mailed / sms-ed to a user about the grid."""

    PRIORITY_CHOICES = [
        ("low", "Low"),
        ("medium", "Medium"),
        ("high", "High"),
        ("critical", "Critical"),
    ]
    DELIVERY_CHOICES = [
        ("sms", "SMS"),
        ("email", "Email"),
        ("push", "Push"),
    ]
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("sent", "Sent"),
        ("failed", "Failed"),
        ("read", "Read"),
    ]

    alert_id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,    # child record of a user
        related_name="alerts",
    )
    alert_type = models.CharField(max_length=50, blank=True)
    priority_level = models.CharField(max_length=10, choices=PRIORITY_CHOICES)
    message = models.TextField()
    sent_at = models.DateTimeField(default=timezone.now)
    delivery_method = models.CharField(max_length=10, choices=DELIVERY_CHOICES)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES)

    class Meta:
        db_table = "alerts"
        constraints = [
            models.CheckConstraint(
                name="chk_alerts_priority_level",
                condition=models.Q(priority_level__in=["low", "medium", "high", "critical"]),
            ),
            models.CheckConstraint(
                name="chk_alerts_delivery_method",
                condition=models.Q(delivery_method__in=["sms", "email", "push"]),
            ),
            models.CheckConstraint(
                name="chk_alerts_status",
                condition=models.Q(status__in=["pending", "sent", "failed", "read"]),
            ),
        ]
        ordering = ["-sent_at"]

    def __str__(self):
        return f"{self.alert_type or 'alert'} [{self.priority_level}] -> {self.user}"
