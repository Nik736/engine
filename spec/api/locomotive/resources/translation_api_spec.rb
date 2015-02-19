require 'spec_helper'

module Locomotive
  module Resources
    describe TranslationAPI do
      include Rack::Test::Methods
      let!(:site) { create(:site, domains: %w{www.acme.com}) }
      let!(:translation) { create(:translation, site: site) }

      let!(:account) { create(:account) }
      let(:params) { { locale: :en } }
      let(:url_prefix) { '/locomotive/acmi/api_test/v2/translations' }

      let!(:membership) do
        create(:admin, account: account, site: site, role: 'admin')
      end

      let(:translation_hash) do
        values = translation.values.stringify_keys
        { 'key' => translation.key, 'values' => values }
      end

      subject { parsed_response }

      context 'no authenticated site' do
        describe "GET /locomotive/acme/api_test/v2/translations/index.json" do
          context 'JSON' do
            it 'returns unauthorized message' do
              get "#{url_prefix}/index.json"
              expect(subject).to eq({ 'error' => '401 Unauthorized' })
            end

            it 'returns unauthorized response' do
              get "#{url_prefix}/index.json"
              expect(last_response.status).to eq(401)
            end
          end
        end
      end

      context 'authenticated site' do
        before do
          header 'X-Locomotive-Account-Token', account.api_token
          header 'X-Locomotive-Account-Email', account.email
          header 'X-Locomotive-Site-Handle', site.handle
        end

        describe "GET index" do
          context 'JSON' do
            before { get "#{url_prefix}/index.json" }
            it 'returns a successful response' do
              expect(last_response).to be_successful
            end

            it 'returns the translation in an array' do
              expect(subject).to eq [translation_hash]
            end
          end
        end

        describe "GET show" do
          context 'JSON' do
            before { get "#{url_prefix}/#{translation.id}.json" }
            it 'returns a successful response' do
              expect(last_response).to be_successful
            end
          end
        end

        describe "POST create" do
          context 'JSON' do
            let(:json) { { key: :site, values: { one: :uno } } }

            it 'creates a translation on the current site' do
              expect{ post("#{url_prefix}.json", translation: json) }
                .to change{ Locomotive::Translation.count }.by(1)
            end
          end
        end

        describe "PUT update" do
          context 'JSON' do
            let(:json) { { key: translation.key, values: { one: :uno } } }
            let(:put_request) { put("#{url_prefix}/#{translation.id}.json", translation: json) }

            it 'does not change the number of existing translations' do
              expect{ put_request }.to_not change{ Locomotive::Translation.count }
            end

            it 'updates the existing translation' do
              expect{ put_request }
                .to change{ Locomotive::Translation.find(translation.id).values }
                .to({ 'one' => 'uno' })
            end
          end
        end

        describe "DELETE destroy" do
          context 'JSON' do
            let(:delete_request) { delete("#{url_prefix}/#{translation.id}.json") }

            it 'deletes the translation' do
              expect{ delete_request }.to change { Locomotive::Translation.count }.by(-1)
            end

            it 'returns the deleted translation' do
              delete_request
              expect(subject).to eq(translation_hash)
            end
          end
        end

      end

    end
  end
end
