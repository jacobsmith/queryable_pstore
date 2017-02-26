require 'minitest/autorun'
require 'queryable_pstore'
require 'csv'

class QueryablePStoreCSVFunctionsTest < Minitest::Test
  CSV_FILENAME = "test.csv"

  def write_test_csv
    ::CSV.open(CSV_FILENAME, "wb") do |csv|
      csv << %w(Name Email Age)
      csv << %w(John john@example.com 23)
      csv << %w(Jane jane@example.com 34)
      csv << %w(Gandalf none 100)
    end
  end

  def delete_test_csv
    File.delete(CSV_FILENAME)
    File.delete(CSV_FILENAME + ".pstore") # delete the auto-created store as well
  end

  def test_import_csv_as_file_location_does_not_blow_up
    write_test_csv
    store = QueryablePStore.import_csv(CSV_FILENAME)
    assert_equal store.name_eq("John").results, [{name: "John", email: "john@example.com", age: "23"}]
    delete_test_csv
  end

  def test_import_csv_can_convert_integers
    write_test_csv
    store = QueryablePStore.import_csv(CSV_FILENAME, convert: [age: :integer])
    assert_equal store.name_eq("John").results, [{name: "John", email: "john@example.com", age: 23}]
    delete_test_csv
  end

  def test_import_csv_can_convert_floats
    write_test_csv
    store = QueryablePStore.import_csv(CSV_FILENAME, convert: [age: :float])
    assert_equal store.name_eq("John").results, [{name: "John", email: "john@example.com", age: 23.0}]
    delete_test_csv
  end

  def test_import_csv_raise_error_on_unknown_conversion
    write_test_csv
    error = assert_raises ArgumentError do
      QueryablePStore.import_csv(CSV_FILENAME, convert: [age: :foobar])
    end
    assert_equal error.message, "Unknown converter: `foobar`"
    delete_test_csv
  end
end
