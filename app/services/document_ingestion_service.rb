class DocumentIngestionService
  def self.call(document_params)
    new.call(document_params)
  end

  def call(document_params)
    document = Document.create!(
      title: document_params[:title] || "Untitled Document",
      source: document_params[:source] || "manual",
      url: document_params[:url],
      raw_content: document_params[:content] || document_params[:raw_content]
    )

    # Chunk the content
    chunks = Knowledge::Chunker.call(document.raw_content)

    # Create chunks with embeddings
    chunks.each do |chunk_content|
      create_chunk_with_embedding(document, chunk_content)
    end

    document
  rescue StandardError => e
    Rails.logger.error "DocumentIngestionService error: #{e.message}"
    raise
  end

  private

  def create_chunk_with_embedding(document, content)
    # Generate embedding first if pgvector is available
    embedding = nil
    if pgvector_available?
      embedding = EmbeddingService.call(content)
    end

    # Create chunk with embedding
    chunk = DocumentChunk.new(
      document: document,
      content: content,
      metadata: {}
    )

    # Set embedding if available (pgvector gem will handle encoding)
    if embedding && pgvector_available?
      chunk.embedding = encode_vector(embedding)
    end

    chunk.save!
  rescue StandardError => e
    Rails.logger.error "Error creating chunk with embedding: #{e.message}"
    # Still create the chunk even if embedding fails
    DocumentChunk.create!(
      document: document,
      content: content,
      metadata: { embedding_error: e.message }
    )
  end

  def encode_vector(vector)
    return nil unless vector.is_a?(Array)
    # pgvector expects a PostgreSQL array format: [1,2,3]
    "[#{vector.join(',')}]"
  end

  def pgvector_available?
    ActiveRecord::Base.connection.extension_enabled?("vector")
  rescue StandardError
    false
  end
end
