# frozen_string_literal: true

require 'test_helper'

module MaintenanceTaskUi
  class JobTest < ActiveJob::TestCase
    class ApplicationJobEnqueueOnInitialize < ApplicationJob
      def initialize(*arguments, task: nil)
        super(*arguments, task: task)
        enqueue
      end
    end

    class SuccessfulJob < ApplicationJobEnqueueOnInitialize
      def build_enumerator(cursor:)
        [1].to_enum
      end

      def each_iteration(*); end

      def complete_progress; end
    end

    class AnotherSuccessfulJob < ApplicationJobEnqueueOnInitialize
      def build_enumerator(cursor:)
        [1].to_enum
      end

      def each_iteration(*); end
    end

    class InterruptedJob < ApplicationJobEnqueueOnInitialize
      class << self
        attr_accessor :should_exit
      end

      def build_enumerator(cursor:)
        [1, 2].to_enum
      end

      def each_iteration(*); end

      def job_should_exit?
        self.class.should_exit
      end
    end

    class RaisingErrorJob < ApplicationJobEnqueueOnInitialize
      attr_reader :progress

      def build_enumerator(cursor:)
        [1, 2].to_enum
      end

      def each_iteration(*)
        raise ArgumentError
      end
    end

    class NonRaisingJob < ApplicationJobEnqueueOnInitialize
      retry_on(ArgumentError)

      class << self
        attr_accessor :should_raise
      end

      def build_enumerator(cursor:)
        [1, 2].to_enum
      end

      def each_iteration(*)
        raise ArgumentError if self.class.should_raise
      end
    end

    test 'task_run gets updated to +running+ when job starts performing' do
      job = SuccessfulJob.new(task: Task.create!(job_class: 'SuccessfulJob'))
      task_run = TaskRun.find_by(job_id: job.job_id)

      assert_equal 'enqueued', task_run.status

      job.perform_now

      assert_equal 'running', task_run.reload.status
    end
  
    test 'task_run gets updated to +succeeded+ when job ends without error' do
      job = AnotherSuccessfulJob.new(task: Task.create!(job_class: 'AnotherSuccessfulJob'))
      task_run = TaskRun.find_by(job_id: job.job_id)

      assert_equal 'enqueued', task_run.status

      job.perform_now

      assert_equal 'succeeded', task_run.reload.status
    end
  
    test 'maintenance task record gets updated to +interrupted+ when job is interrupted' do
      job = InterruptedJob.new(task: Task.create!(job_class: 'InterruptedJob'))
      InterruptedJob.should_exit = true
      task_run = TaskRun.find_by(job_id: job.job_id)

      assert_equal 'enqueued', task_run.status

      job.perform_now

      assert_equal 'interrupted', task_run.reload.status
    end
  
    test 'maintenance task record gets updated to +interrupted+ and new record gets created when job is resumed' do
      job = InterruptedJob.new(task: Task.create!(job_class: 'InterruptedJob'))
      InterruptedJob.should_exit = true
      task_run = TaskRun.find_by(job_id: job.job_id)

      assert_equal 'enqueued', task_run.status

      assert_enqueued_jobs(1, only: InterruptedJob) do
        job.perform_now
      end

      assert_equal 'interrupted', task_run.reload.status

      new_task_run = TaskRun.where(job_id: job.job_id).last
      assert_equal 'enqueued', new_task_run.status

      InterruptedJob.should_exit = false
      job.perform_now

      assert_equal 'succeeded', new_task_run.reload.status
    end
  
    test 'maintenance task record gets updated to +errored+ when job crashes' do
      job = RaisingErrorJob.new(task: Task.create!(job_class: 'RaisingErrorJob'))
      task_run = TaskRun.find_by(job_id: job.job_id)

      assert_equal 'enqueued', task_run.status
  
      job.perform_now

      assert_equal 'errored', task_run.reload.status
      assert_equal 'ArgumentError', task_run.error_class
      assert_equal 'ArgumentError', task_run.error_message
      assert_match %r{application_job_test.rb:[0-9]+:in `each_iteration}, task_run.stack_trace
    end
  
    test 'maintenance task record gets updated to +errored+ and new record gets created when job is retried' do
      job = NonRaisingJob.new(task: Task.create!(job_class: 'NonRaisingJob'))
      task_run = TaskRun.find_by(job_id: job.job_id)
      NonRaisingJob.should_raise = true

      assert_equal 'enqueued', task_run.status

      assert_enqueued_jobs(1, only: NonRaisingJob) do
        job.perform_now
      end

      assert_equal 'errored', task_run.reload.status

      new_task_run = TaskRun.where(job_id: job.job_id).last
      assert_equal 'enqueued', new_task_run.status
  
      NonRaisingJob.should_raise = false
      job.perform_now

      assert_equal 'succeeded', new_task_run.reload.status
    end
  end
end
