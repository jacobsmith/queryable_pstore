Gem::Specification.new do |s|
  s.name        = 'queryable_pstore'
  s.version     = '0.0.1'
  s.date        = '2017-02-25'
  s.summary     = "A simple wrapper for making querying PStores easier."
  s.description = "This provides a very simple way of querying PStores. It allows you to write queries like: `pstore.age_gt(40).height_lt(1.8).results` Additional documentation is available on the GitHub page."
  s.authors     = ["Jacob Smith"]
  s.email       = 'jacob.wesley.smith@gmail.com'
  s.files       = ["lib/queryable_pstore.rb"]
  s.homepage    =
    'http://rubygems.org/gems/queryable_pstore'
  s.license       = 'MIT'
end
