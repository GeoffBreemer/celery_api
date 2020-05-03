from django.contrib import admin
from django.db.models import QuerySet
from django.contrib.messages import SUCCESS

from .models import MedicalReport
from .tasks import add_to_report


@admin.register(MedicalReport)
class MedicalReportAdmin(admin.ModelAdmin):
    list_display = ["report_content", "observation_date"]
    actions = ["trigger_task"]

    def trigger_task(
            self, request, queryset: QuerySet
        ) -> None:
        for mr in queryset:
             add_to_report.apply_async((mr.id, "- more content 10s"), countdown=10)
            # add_to_report.delay(mr_id=mr.id, content="- more content immediate")
            # add_to_report(mr_id=mr.id, content="- more content async")


        self.message_user(request=request, message=f"Update requested 10 seconds from now", level=SUCCESS)
