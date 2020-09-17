# frozen_string_literal: true

require 'test_helper'

class MaintenanceTaskUiTest < ActionDispatch::IntegrationTest
  test '#show display the list of possible running tasks' do
    get '/maintenance_task_ui/tasks'
    assert_response(:ok)

    assert_select 'form[action=?]', '/maintenance_task_ui/tasks/MyTask' do
      assert_select 'input[value=?]', 'Enqueue MyTask'
    end
  end


  test '#show display the list of tasks in the queue after enqueuing a task' do
    post '/maintenance_task_ui/tasks/MyTask'
    assert_response(:ok)

    get '/maintenance_task_ui/tasks'
    assert_response(:ok)

    assert_select('p', text: "MyTask is in the queue.")
  end

  test '#show does not allow a Task to be enqueued if one is already in the queue' do
    post '/maintenance_task_ui/tasks/MyTask'
    assert_response(:ok)

    get '/maintenance_task_ui/tasks'
    assert_response(:ok)

    assert_select('p', text: "MyTask is in the queue.")
    assert_select('form[action=?]', '/maintenance_task_ui/tasks/MyTask', count: 0)
  end

  test '#show display the list of finished tasks' do
    perform_enqueued_jobs do
      post '/maintenance_task_ui/tasks/MyTask'
    end
    assert_response(:ok)

    get '/maintenance_task_ui/tasks'
    assert_response(:ok)

    assert_select('td', text: "MyTask")
    assert_select('td', text: "succeeded")
  end

  test '#show displays the list of running tasks' do
    job = Class.new(MaintenanceTaskUi::ApplicationJob) do
      class_attribute :latch1

      def build_enumerator(*)
        [1].to_enum
      end

      def each_iteration(*)
        latch1.wait
      end
    end
    Maintenance.const_set(:LatchJob, job)

    latch1 = Concurrent::CountDownLatch.new
    latch2 = Concurrent::CountDownLatch.new
    job.latch1 = latch1

    post '/maintenance_task_ui/tasks/LatchJob'
    assert_response(:ok)

    Thread.new {
      perform_enqueued_jobs
      latch2.count_down
    }

    get '/maintenance_task_ui/tasks'
    assert_response(:ok)

    assert_select('p', text: "LatchJob is running.")
    latch1.count_down
    latch2.wait
  ensure
    Maintenance.send(:remove_const, :LatchJob)
  end

  test '#enqueue enqueues a task' do
    assert_enqueued_with(job: Maintenance::MyTask) do
      post '/maintenance_task_ui/tasks/MyTask'
    end

    assert_response(:ok)
    assert_equal 'Task successfully enqueued', response.body
  end

  test '#enqueue enqueues a task with params' do
    tempfile(name: 'params', ext: '.csv', content: "Age\n1") do |file_path|
      csv = mock_file_upload('params.csv', file_path)

      assert_enqueued_with(job: Maintenance::TaskWithParams) do
        post '/maintenance_task_ui/tasks/TaskWithParams', params: { csv: csv }
      end

      assert_response(:ok)
      assert_equal 'Task successfully enqueued', response.body
    end
  end

  test '#enqueue does not enqueue a task when task does not exist' do
    assert_no_enqueued_jobs do
      post '/maintenance_task_ui/tasks/BlablaTask'
    end

    assert_response(:bad_request)
    assert_equal 'This task does not exist', response.body
  end

  test '#enqueue does not enqueue task if params are required and none are included' do
    assert_no_enqueued_jobs do
      post '/maintenance_task_ui/tasks/TaskWithParams'
    end

    assert_response(:bad_request)
    assert_equal 'CSV with task arguments is required', response.body
  end

  test '#enqueue does not enqueue task if the CsvFileValidator contain errors' do
    tempfile(name: 'params', ext: '.csv', content: "Agea\"b\"\n1") do |file_path|
      csv = mock_file_upload('params.csv', file_path)

      assert_no_enqueued_jobs do
        post '/maintenance_task_ui/tasks/TaskWithParams', params: { csv: csv }
      end

      assert_response(:unprocessable_entity)
      assert_equal "CSV was invalid. The following errors were detected:\nIllegal quoting in line 1.", response.body
    end
  end

  test '#detail shows all the runs of a task' do
    perform_enqueued_jobs do
      post '/maintenance_task_ui/tasks/MyTask'
    end
    assert_response(:ok)

    task = MaintenanceTaskUi::Task.last

    get("/maintenance_task_ui/tasks/#{task.id}")
    assert_select('td', text: task.job_class)
    assert_select('td', text: task.task_run.first.job_id)
    assert_select('td', text: "succeeded")
  end

  private

  def tempfile(name:, ext:, content:)
    Tempfile.create([name, ext]) do |file|
      file.write(content)
      file.flush

      yield(file.path)
    end
  end

  def mock_file_upload(name, path)
    mime_type ||= Mime::Type.lookup_by_extension(name.split('.').last).to_s
    Rack::Test::UploadedFile.new(path, mime_type)
  end
end
