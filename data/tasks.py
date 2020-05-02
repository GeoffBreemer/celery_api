from __future__ import absolute_import, unicode_literals

from celery import shared_task
from data.models import MedicalReport


@shared_task
def count_mrs():
    return MedicalReport.objects.count()


@shared_task
def add_to_report(mr_id, content):
    mr = MedicalReport.objects.get(id=mr_id)
    mr.report_content += content
    mr.save()
