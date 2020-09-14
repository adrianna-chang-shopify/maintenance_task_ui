module MaintenanceTaskUi
  class CsvFileValidator
    class FileNotReadableError < StandardError
      def initialize(msg='The file could not be read.')
        super
      end
    end
    class InvalidFileFormatError < StandardError
      def initialize(msg='The file was an invalid format.')
        super
      end
    end
    class EmptyFileError < StandardError
      def initialize(msg='The file was empty.')
        super
      end
    end
    class FileTooLargeError < StandardError
      def initialize(msg='The file was too large. Files must be less than 15 megabytes.')
        super
      end
    end
    class TooManyColumnsError < StandardError
      def initialize(msg='The file contained too many headers. Files not not exceed 100 columns.')
        super
      end
    end
    class MalformedCSVError < StandardError
      def initialize(msg='The file was malformed. Ensure the file is a valid CSV.')
        super
      end
    end

    MAX_IMPORT_FILE_SIZE = 15.megabytes
    MAX_COLUMN_COUNT = 100

    require 'csv'

    VALID_FORMATS = [
      "text/comma-separated-values",
      "text/csv",
      "application/csv",
      "application/excel",
      "application/vnd.ms-excel",
      "application/vnd.msexcel",
      "text/anytext",
      "application/octet-stream",
      "attachment/csv",
      "text/plain",
    ].freeze

    class << self
      def call(csv)
        new(csv: csv).tap(&:validate)
      end
    end

    attr_reader :csv, :errors

    def initialize(csv:, errors: [])
      @csv = csv
      @errors = errors
    end

    def valid?
      errors.empty?
    end

    def validate
      validate_readable
      validate_csv_file_type
      validate_not_blank
      validate_content_size
      validate_content
    rescue StandardError => e
      errors << e
    end

    private

    def validate_readable
      raise FileNotReadableError unless csv.respond_to?(:read)
    end

    def validate_csv_file_type
      return if csv.respond_to?(:content_type) && VALID_FORMATS.include?(csv.content_type)
      raise InvalidFileFormatError
    end

    def validate_not_blank
      return unless csv.respond_to?(:read)
      raise EmptyFileError if csv.read.blank?
    end

    def validate_content_size
      if csv.size > MAX_IMPORT_FILE_SIZE
        raise FileTooLargeError
      end
      if CSV.open(csv, &:readline).size > MAX_COLUMN_COUNT
        raise TooManyColumnsError
      end
    end

    def validate_content
      CSV.read(csv)
    rescue CSV::MalformedCSVError => e
      raise MalformedCSVError
    end
  end
end
