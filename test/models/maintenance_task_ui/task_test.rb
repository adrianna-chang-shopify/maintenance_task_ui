require 'test_helper'

module MaintenanceTaskUi
  class TaskTest < ActiveSupport::TestCase
    test "#status returns the status of the last associated task_run" do
      task = Task.create!(job_class: 'SomeJob')
      task_run = TaskRun.create!(task: task, job_id: 'abc-123', status: :interrupted)
      another_task_run = TaskRun.create!(task: task, job_id: 'xyz-987', status: :succeeded)

      assert_predicate task, :succeeded?
    end

    test "#completed? returns true for succeeded, aborted, and errored tasks" do
      task = Task.create!(job_class: 'SomeJob')
      task_run = TaskRun.create!(task: task, job_id: 'abc-123', status: :succeeded)
      assert_predicate task, :completed?

      task_run.update!(status: :aborted)
      assert_predicate task, :completed?

      task_run.update!(status: :errored, error_class: "ArgumentError", error_message: "Kaboom!", stack_trace: "xyz")
      assert_predicate task, :completed?
    end

    test "#completed? returns false for enqueued, running and interrupted tasks" do
      task = Task.create!(job_class: 'SomeJob')
      task_run = TaskRun.create!(task: task, job_id: 'abc-123', status: :enqueued)
      refute_predicate task, :completed?

      task_run.update!(status: :running)
      refute_predicate task, :completed?

      task_run.update!(status: :interrupted)
      refute_predicate task, :completed?
    end

    test "#completed? returns false for tasks in which a task_run was not created" do
      task = Task.create!(job_class: 'SomeJob')

      assert_equal 'enqueuing_error', task.status
      refute_predicate task, :completed?
    end
  end
end
