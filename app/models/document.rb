class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy

  validates :raw_content, presence: true
end
