require 'test_helper'

module MaintenanceTaskUi
  class TaskRunTest < ActiveSupport::TestCase
    test "requires error_class, error_message, and stack_trace if status is :errored:" do
      task_run = TaskRun.new(job_id: 'abc', task: Task.first)
      assert task_run.valid?

      task_run.status = :errored
      refute task_run.valid?

      [:error_class, :error_message, :stack_trace].each do |key|
        assert_equal ["can't be blank"], task_run.errors[key]
      end

      task_run.error_class = 'ArgumentError'
      task_run.error_message = 'Weve got a problem, mate'
      task_run.stack_trace = 'test/job_test.rb:51:in `each_iteration`\n'

      assert task_run.valid?
    end

    test "#finished? returns whether the task run has finished or not" do
      task_run = TaskRun.new(job_id: 'abc', task: Task.first)
      refute task_run.finished?

      task_run.status = 'running'
      refute task_run.finished?

      ['succeeded', 'aborted', 'interrupted', 'errored'].each do |status|
        task_run.status = status
        assert task_run.finished?
      end
    end
  end
end
