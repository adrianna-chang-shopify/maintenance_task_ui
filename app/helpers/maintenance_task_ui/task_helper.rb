module MaintenanceTaskUi
  module TaskHelper
    def accepts_params?(task)
      # For ActiveJob, Maintenance.const_get(task).instance_method(:perform).arity > 0
      Maintenance.const_get(task).instance_method(:build_enumerator).arity > 1
    end
  end
end

