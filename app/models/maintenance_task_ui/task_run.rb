module MaintenanceTaskUi
  class TaskRun < ApplicationRecord
    # Various state of a job:
    #
    # enqueued      When the job is in the Redis queue
    # running       When the job is being performed
    # succeeded     When the job finished performing without error
    # aborted       When the user explicitely halted the job execution
    # interrupted   When the job was interrupted in the middle of the run (infrastructure issue, used paused the job)
    # errored       When the job couldn't finish because of a problem (wrong code)
    enum status: [:enqueued, :running, :succeeded, :aborted, :interrupted, :errored]

    belongs_to :task

    validates_presence_of :error_class, :error_message, :stack_trace, if: -> { status == 'errored' }

    def finished?
      status == 'succeeded' || status == 'aborted' || status == 'interrupted' || status == 'errored'
    end
  end
end
