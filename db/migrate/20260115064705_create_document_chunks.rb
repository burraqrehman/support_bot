class CreateDocumentChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    # pgvector is optional in dev/test if the PostgreSQL server doesn't have the
    # extension installed. When available, add the embedding column + ANN index.
    return unless extension_enabled?("vector")

    add_column :document_chunks, :embedding, :vector, limit: 1536 # depends on your embedding model
    add_index :document_chunks, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
