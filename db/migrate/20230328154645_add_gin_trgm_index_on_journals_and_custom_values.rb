class AddGinTrgmIndexOnJournalsAndCustomValues < ActiveRecord::Migration[7.0]
  def change
    enable_extension("pg_trgm")

    add_index(:journals, :notes, using: 'gin', opclass: :gin_trgm_ops)
    add_index(:custom_values, :value, using: 'gin', opclass: :gin_trgm_ops)
  end
end
