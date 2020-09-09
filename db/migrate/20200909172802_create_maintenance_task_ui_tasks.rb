class CreateMaintenanceTaskUiTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :maintenance_task_ui_tasks do |t|
      t.string :job_class, null: false

      t.timestamps
    end
  end
end
