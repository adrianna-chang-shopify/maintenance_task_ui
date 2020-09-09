Rails.application.routes.draw do
  mount MaintenanceTaskUi::Engine => "/maintenance_task_ui"
end
