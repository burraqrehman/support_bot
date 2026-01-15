class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :source
      t.string :url
      t.text :raw_content

      t.timestamps
    end
  end
end
