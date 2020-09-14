require 'test_helper'
require 'tempfile'

module MaintenanceTaskUi
  class CsvFileValidatorTest < ActiveSupport::TestCase
    test ".call is successful on valid CSV file" do
      valid_csv_content = "Name,Age,Birthday\nBetty,1,2020-09-11\nFido,2,2020-09-08"
      tempfile(name: 'good', ext: '.csv', content: valid_csv_content) do |file_path|
        csv = mock_file_upload('good.csv', file_path)
        assert_predicate CsvFileValidator.call(csv), :valid?
      end
    end

    test ".call flags error if CSV file is not readable" do
      tempfile(name: 'unreadable', ext: '.csv', content: 'xyz') do |file_path|
        csv = mock_file_upload('unreadable.csv', file_path)
        csv.stubs(:respond_to?).with(:read).returns(false)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::FileNotReadableError
      end
    end

    test ".call flags error if CSV file is not a valid CSV format" do
      tempfile(name: 'not_a_csv', ext: '.rb', content: 'xyz') do |file_path|
        csv = mock_file_upload('not_a_csv.rb', file_path)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::InvalidFileFormatError
      end
    end

    test ".call flags error if CSV file is empty" do
      tempfile(name: 'empty', ext: '.csv', content: '') do |file_path|
        csv = mock_file_upload('empty.csv', file_path)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::EmptyFileError
      end
    end

    test ".call flags error if CSV file is too large" do
      tempfile(name: 'too_big', ext: '.csv', content: "xyz") do |file_path|
        csv = mock_file_upload('too_big.csv', file_path)
        csv.stubs(:size).returns(CsvFileValidator::MAX_IMPORT_FILE_SIZE + 1)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::FileTooLargeError
      end
    end

    test ".call flags error if CSV file has too many headers" do
      headers = "Name," * (CsvFileValidator::MAX_COLUMN_COUNT + 1)
      tempfile(name: 'too_big', ext: 'csv', content: headers) do |file_path|
        csv = mock_file_upload('too_big.csv', file_path)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::TooManyColumnsError
      end
    end

    test ".call flags error if CSV file is malformed" do
      malformed_content = "Name,Age,Birthday\nBetty,1,2020-09-11,a\"b\"c\nFido,2,2020-09-08"
      tempfile(name: 'malformed', ext: '.csv', content: malformed_content) do |file_path|
        csv = mock_file_upload('malformed.csv', file_path)

        validation = CsvFileValidator.call(csv)

        refute_predicate validation, :valid?
        assert_includes validation.errors.map(&:class), CsvFileValidator::MalformedCSVError
      end
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
end
