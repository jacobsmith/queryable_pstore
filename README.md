# QueryablePStore
QueryablePStore is a quick and easy way to query a PStore file. It's syntax is inspired by ActiveRecord, but is more simplified. Of note, appending `.results` is required to actually execute the query and return the results.

## Examples:

Assuming a `testing.pstore` file that has the following hash saved:

```ruby
{
  1: { name: "John Doe", age: 28, weight: 150.0, email: "john_doe@example.com" },
  2: { name: "Alpha Bet", age: 18, weight: 170.0, email: "alpha_bet@example.com" },
  3: { name: "Charlie Dog", age: 46, weight: 182.9, email: "charlie_dog@example2.com" },
  4: { name: "Eddy Foobar", age: 72, weight: 200.0, email: "eddy_foobar@example2.com" },
  5: { name: "George Hallo", age: 50, weight: 246.0, email: "george_hallo@example2.com" },
}
```

- All users older than 30:

```ruby
q = QueryablePStore.new("testing.pstore")
q.age_gt(30).results
```

- All Users younger than 60 with a weight greater than 100:

```ruby
q = QueryablePStore.new("testing.pstore")
q.age_lt(60).weight_gt(100.0).results
```

The `attributes_lambda` function recieves the entire record wrapped in an OpenStruct, so both `[]` and dot-notation access methods are supported.
- All Users with an email ending with `example.com`:

```ruby
q = QueryablePStore.new("testing.pstore")
q.attributes_lambda { |row| row.email.end_with?("example.com") }.results
# OR
q.attributes_lambda { |row| row[:email].end_with?("example.com") }.results
```

## CSV Import

The library also supports importing a CSV that is already written to disk. It will then create a PStore at the location `#{filename}.pstore` and return an instance of a QueryablePStore loaded for you to use.

```ruby
q = QueryablePStore.import_csv("test.csv")
q.name_eq("John Doe").results
```

It will normalize all headers to lowercase symbols, but may run in to trouble with headers with odd characters in the name or spaces.

Additionally, you can let QueryablePStore know how to convert integer and float fields so that `gt` and `lt` queries can use numbers rather than strings for comparisons.

```ruby
q = QueryablePStore.import_csv("test.csv", convert: [age: :integer])
q.age_gt(20).results
```

