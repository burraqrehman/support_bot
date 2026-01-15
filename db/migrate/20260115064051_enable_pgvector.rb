class EnablePgvector < ActiveRecord::Migration[8.0]
  # If pgvector isn't installed, attempting to enable the extension will raise,
  # and (when run inside a migration transaction) will abort the entire
  # transaction, causing later statements to fail with InFailedSqlTransaction
  # even if we rescue the original exception.
  #
  # Running this migration without a surrounding DDL transaction avoids that.
  disable_ddl_transaction!

  def change
    return if extension_enabled?("vector")

    enable_extension "vector"
  rescue ActiveRecord::StatementInvalid => e
    # If pgvector isn't installed on the local PostgreSQL server, enabling the
    # extension will fail with something like:
    #   PG::FeatureNotSupported: extension "vector" is not available
    #
    # We allow dev/test to proceed without pgvector so the rest of the schema can
    # be migrated. Production should still fail loudly.
    if Rails.env.production?
      raise
    end

    warn <<~MSG
      [WARN] Skipping pgvector extension enablement because it isn't available on this PostgreSQL instance.
             Install pgvector for your Postgres server, then re-run migrations.
             Original error: #{e.cause&.message || e.message}
    MSG
  end
end
