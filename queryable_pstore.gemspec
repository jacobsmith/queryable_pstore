Gem::Specification.new do |s|
  s.name        = 'queryable_pstore'
  s.version     = '0.0.7'
  s.date        = '2017-03-04'
  s.summary     = "A simple wrapper for making querying PStores easier."
  s.description = "This provides a very simple way of querying PStores. It allows you to write queries like: `pstore.age_gt(40).height_lt(1.8).results` Additional documentation is available on the GitHub page."
  s.authors     = ["Jacob Smith"]
  s.email       = 'jacob.wesley.smith@gmail.com'
  s.files       = Dir["lib/*.rb"]
  s.homepage    =
    'https://github.com/jacobsmith/queryable_pstore'
  s.license       = 'MIT'
end
