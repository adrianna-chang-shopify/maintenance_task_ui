module MaintenanceTaskUi
  class UploadedCsvSerializer < ActiveJob::Serializers::ObjectSerializer
    def serialize?(argument)
      argument.is_a? ActionDispatch::Http::UploadedFile
    end

    def serialize(file)
      file.tempfile.rewind if file.tempfile.eof?
      super("csv" => file.tempfile.read)
    end

    def deserialize(hash)
      CSV.new(hash["csv"], headers: true)
    end
  end
end
