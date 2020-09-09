class CreateMaintenanceTaskUiTaskRuns < ActiveRecord::Migration[6.0]
  def change
    create_table :maintenance_task_ui_task_runs do |t|
      t.string :job_id
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :status, default: 0
      t.string :error_class
      t.string :error_message
      t.text :strack_trace
      t.references :task

      t.timestamps
    end
  end
end
