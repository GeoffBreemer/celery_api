from django.db import models


class MedicalReport(models.Model):
    report_content = models.CharField(max_length=200)
    observation_date = models.DateTimeField(verbose_name="observation date")

    def __str__(self):
        return f"{self.pk} on {self.observation_date}"
