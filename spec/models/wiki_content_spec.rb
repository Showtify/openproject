#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe WikiContent do
  let(:content) { create(:wiki_content, page:, author:) }

  shared_let(:wiki) { create(:wiki) }
  shared_let(:page) { create(:wiki_page, wiki:) }
  shared_let(:author) do
    create(:user,
           firstname: 'author',
           member_in_project: wiki.project,
           member_with_permissions: [:view_wiki_pages])
  end
  shared_let(:project_watcher) do
    create(:user,
           firstname: 'project_watcher',
           member_in_project: wiki.project,
           member_with_permissions: [:view_wiki_pages],
           notification_settings: [
             build(:notification_setting,
                   wiki_page_added: true,
                   wiki_page_updated: true)
           ])
  end

  shared_let(:wiki_watcher) do
    watcher = create(:user,
                     firstname: 'wiki_watcher',
                     member_in_project: wiki.project,
                     member_with_permissions: [:view_wiki_pages],
                     notification_settings: [
                       build(:notification_setting,
                             wiki_page_added: true,
                             wiki_page_updated: true)
                     ])
    wiki.watcher_users << watcher

    watcher
  end

  describe 'mail sending' do
    context 'when creating' do
      let(:content) { build(:wiki_content, page:, author:) }

      it 'sends mails to the wiki`s watchers and project all watchers' do
        expect do
          perform_enqueued_jobs do
            User.execute_as(author) do
              content.save!
            end
          end
        end
          .to change { ActionMailer::Base.deliveries.size }
                .by(2)
      end
    end

    context 'when updating',
            with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:page_watcher) do
        watcher = create(:user,
                         firstname: 'page_watcher',
                         member_in_project: wiki.project,
                         member_with_permissions: [:view_wiki_pages],
                         notification_settings: [
                           build(:notification_setting, wiki_page_updated: true)
                         ])
        page.watcher_users << watcher

        watcher
      end

      before do
        page_watcher

        content.text = 'My new content'
      end

      it 'sends mails to the watchers, the wiki`s watchers and project all watchers' do
        expect do
          perform_enqueued_jobs do
            User.execute_as(author) do
              content.save!
            end
          end
        end
          .to change { ActionMailer::Base.deliveries.size }
                .by(3)
      end
    end
  end
end
