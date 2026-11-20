# frozen_string_literal: true

require 'rails_helper'

describe Maglev::PreviewConstraint do
  subject { described_class.new.matches?(request) }

  let(:accept) { nil }
  let(:user_agent) { 'curl/8.5.0' }
  let(:path) { '/about' }
  let(:upgrade) { nil }
  let(:request) do
    env = Rack::MockRequest.env_for(path)
    env['HTTP_USER_AGENT'] = user_agent
    env['HTTP_ACCEPT'] = accept if accept
    env['HTTP_UPGRADE'] = upgrade if upgrade
    ActionDispatch::Request.new(env)
  end

  context 'without an Accept header' do
    it { is_expected.to be(true) }
  end

  context 'with a browser Accept header' do
    let(:accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' }

    it { is_expected.to be(true) }
  end

  context 'with Accept */*' do
    let(:accept) { '*/*' }

    it { is_expected.to be(true) }

    %w[/app.js /style.css /logo.png /data.json /app.js.map /favicon.ico].each do |asset_path|
      context "on an asset-like path (#{asset_path})" do
        let(:path) { asset_path }

        it { is_expected.to be(false) }
      end
    end

    context 'on a page path with an .html extension' do
      let(:path) { '/about.html' }

      it { is_expected.to be(true) }
    end
  end

  context 'with Accept application/json' do
    let(:accept) { 'application/json' }

    it { is_expected.to be(false) }
  end

  context 'with Accept image/*' do
    let(:accept) { 'image/webp,image/*' }

    it { is_expected.to be(false) }
  end

  context 'with a known crawler and an unrecognised Accept header' do
    let(:accept) { 'foo/bar' }
    let(:user_agent) { 'Googlebot/2.1' }

    it { is_expected.to be(true) }
  end

  context 'with a websocket upgrade' do
    let(:accept) { '*/*' }
    let(:path) { '/cable' }
    let(:upgrade) { 'websocket' }

    it { is_expected.to be(false) }
  end
end
