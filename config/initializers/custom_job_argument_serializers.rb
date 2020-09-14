require "maintenance_task_ui/uploaded_csv_serializer"

ActiveJob::Serializers.add_serializers(MaintenanceTaskUi::UploadedCsvSerializer)
