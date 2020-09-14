require_relative '../../config/initializers/custom_job_argument_serializers'

module MaintenanceTaskUi
  class Engine < ::Rails::Engine
    isolate_namespace MaintenanceTaskUi
  end
end
