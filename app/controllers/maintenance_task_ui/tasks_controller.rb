module MaintenanceTaskUi
  class TasksController < ApplicationController
    def show
      @tasks = Task.preload(:task_run).all
      running_tasks = @tasks.select { |task| task.running? || task.enqueued? }
      @available_tasks = Maintenance.constants.map(&:to_s) - running_tasks.pluck(:job_class)
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
        task_const = Maintenance.const_get(params[:task])

        job = if accepts_params?(task_const)
          return render(plain: "CSV with task arguments is required") unless params[:csv].present?
          
          result = CsvFileValidator.call(params[:csv])
          if result.valid?
            task_const.perform_later(params[:csv], task: task)
          else
            errors = result.errors.map(&:message).join("\n")
            render(plain: "CSV was invalid. The following errors were detected:\n#{errors}", status: :unprocessable_entity)
          end  
        else
          task_const.perform_later(task: task)
        end

        if job.present?
          render(plain: 'Task successfully enqueued')
        else
          render(plain: 'Failed to enqueue task')
        end
      else
        render(plain: 'This task does not exist', status: :unprocessable_entity)
      end
    end

    private

    def accepts_params?(task_const)
      # For ActiveJob, Maintenance.const_get(task).instance_method(:perform).arity > 0
      task_const.instance_method(:build_enumerator).arity > 1
    end
  end
end
