# frozen_string_literal: true

module Maintenance
  class MyTask < MaintenanceTaskUi::ApplicationJob
    def build_enumerator(cursor:)
      enumerator_builder.active_record_on_records(
        Dog.where('age >= 3'),
        cursor: cursor,
      )
    end

    def each_iteration(dog)
      sleep(5)

      dog.update!(age: rand(1..22))
    end
  end
end
