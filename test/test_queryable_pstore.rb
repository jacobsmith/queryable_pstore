require 'minitest/autorun'
require 'queryable_pstore'

class QueryablePStoreTest < Minitest::Test
  TEST_FILENAME = "test.pstore"
  JOHN = { name: "John Doe", email: "jdoe@example.com", age: 32 }
  JANE = { name: "Jane Doe", email: "jane_doe@example.com", age: 25 }
  GANDALF = { name: "Gandalf", email: "none", age: 150 }

  def setup_pstore
    store = PStore.new(TEST_FILENAME)
    store.transaction do
      store[1] = JOHN
      store[2] = JANE
      store[3] = GANDALF
    end

    QueryablePStore.new(TEST_FILENAME)
  end

  Minitest.after_run do
    File.delete(TEST_FILENAME)
  end

  def test_load_pstore
    queryable_pstore = setup_pstore
    assert_equal queryable_pstore.records, [JOHN, JANE, GANDALF]
  end

  def test_attribute_present_equals
    queryable_pstore = setup_pstore
    assert_equal [JOHN], queryable_pstore.name_eq("John Doe").results
  end

  def test_attribute_not_present_equals
    queryable_pstore = setup_pstore

    error = assert_raises ArgumentError do
      queryable_pstore.foobar_eq("foobaz").results
    end

    assert_equal error.message, "The attribute `foobar` is not present in the PStore."
  end

  def test_lambda_function_valid
    queryable_pstore = setup_pstore
    assert_equal queryable_pstore.attributes_lambda { |record| record.name == "John Doe" }.results, [JOHN]
  end

  def test_pluck_method
    queryable_pstore = setup_pstore
    assert_equal queryable_pstore.pluck(:name).results, ["John Doe", "Jane Doe", "Gandalf"]
  end
end
