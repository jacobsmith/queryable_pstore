require 'minitest/autorun'
require "minitest/focus"
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

    Dir.glob(["*.pstore"]).each do |pstore|
      File.delete(pstore) # delete the auto-created store as well
    end
  end

  def test_import_csv_with_save_to_location
    write_test_csv
    store = QueryablePStore.import_csv(CSV_FILENAME, save_to_location: "tmp/")
    assert_equal Dir.glob("tmp/*.pstore").length, 1

    delete_test_csv
    File.delete("tmp/#{CSV_FILENAME}.pstore")
    FileUtils.rmdir("tmp/")
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

  def test_import_csv_return_headers
    write_test_csv
    store = QueryablePStore.import_csv(CSV_FILENAME, convert: [age: :float])
    assert_equal store.original_headers, ["Name", "Email", "Age"]
    assert_equal store.headers_and_type, {"Name" => String, "Email" => String, "Age" => Float}
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

  def test_queryable_headers_conversion_method
    assert_equal QueryablePStore.queryable_header("hello"), :hello
    assert_equal QueryablePStore.queryable_header("hello-there"), :hello_there
    assert_equal QueryablePStore.queryable_header("Name"), :name
  end

  def test_import_csv_as_string
    write_test_csv
    csv_string = File.read(CSV_FILENAME)

    store = QueryablePStore.import_csv_from_string(csv_string)
    assert_equal store.name_eq("John").results, [{name: "John", email: "john@example.com", age: "23"}]
    delete_test_csv
  end
end
