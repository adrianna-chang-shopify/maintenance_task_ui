module MaintenanceTaskUi
  class ApplicationJob < ActiveJob::Base
    include JobIteration::Iteration
  end
end
