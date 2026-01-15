module Knowledge
    class Chunker
      # naive chunker; replace with better token-based chunking later
      def self.call(text, max_chars: 1200)
        return [] if text.blank?
  
        text
          .gsub(/\r\n?/, "\n")
          .split("\n\n")
          .flat_map { |para| para.scan(/.{1,#{max_chars}}/m) }
          .map(&:strip)
          .reject(&:blank?)
      end
    end
  end
  