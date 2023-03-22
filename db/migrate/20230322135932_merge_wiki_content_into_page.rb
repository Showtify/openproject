class MergeWikiContentIntoPage < ActiveRecord::Migration[7.0]
  def change
    change_table :wiki_pages, bulk: true do |t|
      t.references :author, index: true, null: true, foreign_key: { to_table: :users }# TODO: switch to not null
      t.text :text, limit: 16.megabytes
      t.integer :lock_version, null: false # TODO: switch to not null
    end

    add_index :wiki_pages, :updated_at


    # TODO: migrate data

    drop_table :wiki_contents do |t|
      t.integer :page_id, null: false
      t.integer :author_id
      t.text :text, limit: 16.megabytes
      t.datetime :updated_at, null: false
      t.integer :lock_version, null: false

      t.index :author_id, name: 'index_wiki_contents_on_author_id'
      t.index :page_id, name: 'wiki_contents_page_id'
      t.index %i[page_id updated_at]
    end

    # TOOD: rename 'WikiContent' to 'WikiPage' in journals 'journable_type'
    # TOOD: rename 'WikiContentJournal' to 'WikiPageJournal' in journals 'data_type'

    rename_table :wiki_content_journals, :wiki_page_journals

    remove_column :wiki_page_journals, :page_id, :bigint
  end
end
