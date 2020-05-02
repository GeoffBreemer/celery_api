from data.models import MedicalReport
from django.contrib.auth import get_user_model
from django.utils.timezone import now

User = get_user_model()


def create_super_user() -> User:
    """Creates the Super User."""
    super_user = User.objects.create(
        username="superuser",
    )
    super_user.set_password("lala")
    super_user.is_active = True
    super_user.is_staff = True
    super_user.is_superuser = True
    super_user.save()

    return super_user


def create_data() -> None:
    """Creates some fake data."""
    MedicalReport.objects.create(
        observation_date=now(),
        report_content=f"Some fake report."
    )


def run():
    create_super_user()
    create_data()
