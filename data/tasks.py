from __future__ import absolute_import, unicode_literals

from celery import shared_task
from data.models import MedicalReport

from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)


@shared_task
def count_mrs():
    logger.info(f"Executing add_to_report")

    return MedicalReport.objects.count()


@shared_task
def add_to_report(mr_id, content):
    logger.info(f"Executing add_to_report")

    mr = MedicalReport.objects.get(id=mr_id)
    mr.report_content += content
    mr.save()
