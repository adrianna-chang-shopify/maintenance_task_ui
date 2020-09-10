module MaintenanceTaskUi
  class TasksController < ApplicationController
    def show
      @tasks = Maintenance.constants
      @enqueued_tasks = TaskRun.where(status: :enqueued)
      @running_tasks = TaskRun.where(status: :running)
      @finished_tasks = TaskRun.where(status: :succeeded)
    end

    def detail
      @task = Task.joins(:task_run).find(params[:task_id])
    end
  
    def enqueue
      if Maintenance.constants.include?(params[:task].to_sym)
        # This can cause issues if a new task is being added and web workers finish
        # deploying before job workers. The task would get enqueued but the job
        # workers won't have that task yet. Need to find a way to prevent that.
        task = Task.create!(job_class: params[:task])
  
        if job = Maintenance.const_get(params[:task]).perform_later(task: task)
          render(plain: 'Task successfully enqueued')
        else
          render(plain: 'Failed to enqueue task')
        end
      else
        render(plain: 'This task does not exist', status: :unprocessable_entity)
      end
    end
  end
end