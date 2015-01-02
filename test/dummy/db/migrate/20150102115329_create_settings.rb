class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.belongs_to :assignable, :polymorphic => true

      t.string :name
      t.text   :value

      t.timestamps
    end
  end
end