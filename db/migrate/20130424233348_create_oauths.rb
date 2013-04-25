class CreateOauths < ActiveRecord::Migration
  def change
    create_table :oauths do |t|

      t.timestamps
    end
  end
end
