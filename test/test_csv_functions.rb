require 'minitest/autorun'
require 'queryable_pstore'
require 'csv'

class QueryablePStoreCSVFunctionsTest < Minitest::Test
  CSV_FILENAME = "test.csv"
  DEFAULT_HEADERS = %w(Name Email Age)
  DEFAULT_ROWS = [
    %w(John john@example.com 23),
    %w(Jane jane@example.com 34),
    %w(Gandalf none 100)
  ]

  def write_test_csv(headers: DEFAULT_HEADERS, rows: DEFAULT_ROWS)
    ::CSV.open(CSV_FILENAME, "wb") do |csv|
      csv << headers
      rows.each do |row|
        csv << row
      end
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

  def test_import_csv_with_special_characters_in_headers
    foobar = ["foobar", "300", "Smith"]
    foobaz = ["foobaz", "400", "Jones"]
    bazquik = ["bazquik", "200", "Johnson"]

    write_test_csv(
      headers: ["Hello World", "$/yr", "First-Last"],
      rows: [
        foobar,
        foobaz,
        bazquik
      ]
    )

    store = QueryablePStore.import_csv(CSV_FILENAME)
    assert_equal store.hello_world_eq("foobar").results.size, 1
    assert_equal store.hello_world_eq("foobar").results.first.values, foobar

    assert_equal store.__yr_eq("400").results.size, 1
    assert_equal store.__yr_eq("400").results.first.values, foobaz

    assert_equal store.first_last_eq("Johnson").results.size, 1
    assert_equal store.first_last_eq("Johnson").results.first.values, bazquik
  end
end
