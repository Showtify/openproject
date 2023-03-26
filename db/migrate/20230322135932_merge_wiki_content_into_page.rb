class MergeWikiContentIntoPage < ActiveRecord::Migration[7.0]
  def change
    change_table :wiki_pages, bulk: true do |t|
      t.references :author, index: true, null: true, foreign_key: { to_table: :users }
      t.text :text, limit: 16.megabytes
      t.integer :lock_version, null: true
    end

    add_index :wiki_pages, :updated_at

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE
            wiki_pages
          SET
            text = wiki_contents.text,
            author_id = wiki_contents.author_id,
            lock_version = wiki_contents.lock_version
          FROM
            wiki_contents
          WHERE
            wiki_contents.page_id = wiki_pages.id
        SQL

        execute <<~SQL.squish
          UPDATE
            journals
          SET
            journable_id = wiki_contents.page_id,
            journable_type = 'WikiPage',
            data_type = 'Journal::WikiPageJournal'
          FROM
            wiki_contents
          WHERE
            journals.journable_id = wiki_contents.id
          AND
            journals.journable_type = 'WikiContent'
          AND
            journals.data_type = 'Journal::WikiContentJournal'
        SQL
      end
      dir.down do
        execute <<~SQL.squish
          INSERT INTO
            wiki_contents (
              page_id,
              author_id,
              text,
              updated_at,
              lock_version
            )
          SELECT
            id,
            author_id,
            text,
            updated_at,
            lock_version
          FROM
            wiki_pages
        SQL

        execute <<~SQL.squish
          UPDATE
            journals
          SET
            journable_id = wiki_contents.id,
            journable_type = 'WikiContent',
            data_type = 'Journal::WikiContentJournal'
          FROM
            wiki_contents
          WHERE
            journals.journable_id = wiki_contents.page_id
          AND
            journals.journable_type = 'WikiPage'
          AND
            journals.data_type = 'Journal::WikiPageJournal'
        SQL
      end
    end

    change_column_null :wiki_pages, :lock_version, false
    change_column_null :wiki_pages, :author_id, false

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

    rename_table :wiki_content_journals, :wiki_page_journals

    remove_column :wiki_page_journals, :page_id, :bigint
  end
end
