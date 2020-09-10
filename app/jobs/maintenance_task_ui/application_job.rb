module MaintenanceTaskUi
  class ApplicationJob < ActiveJob::Base
    include JobIteration::Iteration

    before_enqueue(:create_record)
    before_perform(:job_running)
    around_perform(:catch_exceptions)
    on_complete(:complete_progress)

    attr_accessor :task

    def initialize(*arguments, task: nil)
      super(*arguments)

      @task = task
    end

    def serialize
      super.tap do |payload|
        payload['task'] = task.to_gid
      end
    end

    def deserialize(job_data)
      super

      task = GlobalID::Locator.locate(job_data['task'])
    end

    def complete_progress
      task_run.update!(status: :succeeded, completed_at: Time.now.utc)
    end

    private

    def catch_exceptions
      yield
    rescue => exception
      # Should we re-raise ? If we do we'll let the adapter (sidekiq/resqueue) automatically
      # retry which we might not want.
      exception_class = exception.class.to_s
      stack_trace = exception.backtrace[0, 10].join('\n')

      task_run.update!(
        status: :errored,
        completed_at: Time.now.utc,
        error_class: exception_class,
        error_message: exception.message,
        stack_trace: stack_trace
      )
      rescue_with_handler(exception)
    end

    def job_running
      task_run.update!(status: :running, started_at: Time.now.utc)
    end

    def create_record
      @task_run = TaskRun.create!(
        job_id: job_id,
        started_at: Time.now.utc,
        task: task
      )
    end

    def task_run
      @task_run ||= TaskRun.where(job_id: job_id).last
    end

    def reenqueue_iteration_job
      task_run.update!(status: :interrupted)

      super
    end
  end
end
