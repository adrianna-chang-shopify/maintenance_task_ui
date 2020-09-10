module MaintenanceTaskUi
  class Task < ApplicationRecord
    has_many :task_run
  end
end
