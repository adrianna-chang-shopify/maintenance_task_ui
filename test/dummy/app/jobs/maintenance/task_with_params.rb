# frozen_string_literal: true

module Maintenance
  class TaskWithParams < MaintenanceTaskUi::ApplicationJob
    def build_enumerator(csv, cursor:)
      params = csv.read
      age = params["Age"].first
      enumerator_builder.active_record_on_records(
        Dog.where("age >= #{age}"),
        cursor: cursor,
      )
    end

    def each_iteration(dog, _params)
      sleep(5)

      dog.update!(age: rand(1..22))
    end
  end
end
