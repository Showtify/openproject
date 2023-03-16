class AddRepositoryHtmlUrl < ActiveRecord::Migration[7.0]
  def change
    change_table :github_pull_requests, bulk: true do |t|
      t.string :repository_html_url
    end

    execute "UPDATE github_pull_requests SET repository_html_url = CONCAT('https://github.com/', repository)"
  end
end
