class SemanticSearchService
  DEFAULT_LIMIT = 5
  DEFAULT_THRESHOLD = 0.7

  def self.call(query, limit: DEFAULT_LIMIT, threshold: DEFAULT_THRESHOLD)
    new.call(query, limit: limit, threshold: threshold)
  end

  def call(query, limit: DEFAULT_LIMIT, threshold: DEFAULT_THRESHOLD)
    return [] if query.blank?

    # Generate embedding for the query
    query_embedding = EmbeddingService.call(query)
    return [] unless query_embedding

    # Check if pgvector extension is available
    unless pgvector_available?
      Rails.logger.warn "pgvector not available, falling back to text search"
      return fallback_text_search(query, limit)
    end

    # Perform vector similarity search
    search_by_embedding(query_embedding, limit, threshold)
  rescue StandardError => e
    Rails.logger.error "SemanticSearchService error: #{e.message}"
    fallback_text_search(query, limit)
  end

  private

  def search_by_embedding(query_embedding, limit, threshold)
    # Use pgvector's cosine distance operator
    # Lower distance = higher similarity
    # The pgvector gem handles encoding automatically when using the vector column type
    encoded_vector = encode_vector(query_embedding)
    
    chunks = DocumentChunk
      .where.not(embedding: nil)
      .order(Arel.sql("embedding <=> '#{encoded_vector}'::vector"))
      .limit(limit * 2) # Get more to filter by threshold
    
    # Filter by similarity threshold
    chunks.select do |chunk|
      chunk_embedding = decode_vector(chunk.embedding)
      next false unless chunk_embedding
      cosine_similarity(query_embedding, chunk_embedding) >= threshold
    end.first(limit)
  end

  def encode_vector(vector)
    return nil unless vector.is_a?(Array)
    # pgvector expects a PostgreSQL array format: [1,2,3]
    "[#{vector.join(',')}]"
  end

  def decode_vector(encoded)
    return nil unless encoded
    return encoded if encoded.is_a?(Array)
    
    # Try to parse if it's a string representation
    if encoded.is_a?(String)
      # Handle PostgreSQL array format or JSON array
      if encoded.start_with?('[')
        JSON.parse(encoded) rescue nil
      else
        # Might be a binary format, try PgVector.decode if available
        defined?(PgVector) && PgVector.respond_to?(:decode) ? PgVector.decode(encoded) : nil
      end
    else
      encoded
    end
  end

  def fallback_text_search(query, limit)
    # Fallback to PostgreSQL full-text search when pgvector isn't available
    terms = query.split(/\s+/).map { |t| "%#{t}%" }
    DocumentChunk
      .where(terms.map { |term| "content ILIKE ?" }.join(" OR "), *terms)
      .limit(limit)
  end

  def cosine_similarity(vec1, vec2)
    return 0.0 unless vec1 && vec2 && vec1.length == vec2.length

    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |x| x * x })
    magnitude2 = Math.sqrt(vec2.sum { |x| x * x })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    dot_product / (magnitude1 * magnitude2)
  end

  def pgvector_available?
    ActiveRecord::Base.connection.extension_enabled?("vector")
  rescue StandardError
    false
  end
end
