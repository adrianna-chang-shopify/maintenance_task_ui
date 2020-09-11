module MaintenanceTaskUi
  class Task < ApplicationRecord
    has_many :task_run

    def status
      (task_run.last&.status || 'enqueuing_error').inquiry
    end

    delegate :enqueued?, :running?, :succeeded?, :aborted?, :interrupted?, :errored?, to: :status

    def completed?
      status.succeeded? || status.aborted? || status.errored?
    end
  end
end
