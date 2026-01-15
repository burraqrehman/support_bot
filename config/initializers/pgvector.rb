begin
  # pgvector doesn't expose `pgvector/active_record` in all versions.
  # Requiring `pgvector` is enough for the gem to hook into ActiveRecord when supported.
  require "pgvector"
rescue LoadError
  # Allow the app to boot even if pgvector isn't installed in the current bundle.
end

