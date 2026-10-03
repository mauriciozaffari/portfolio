# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content::Markdown do
  def render(source)
    described_class.to_html(source)
  end

  describe 'prose' do
    it 'renders the constructs the corpus actually uses' do
      html = render("## Problem\n\nA **bold** claim about `strict_loading`.")

      expect(html).to include('<h2>Problem</h2>')
      expect(html).to include('<strong>bold</strong>')
      expect(html).to include('<code>strict_loading</code>')
    end

    it 'leaves an intraword underscore alone' do
      expect(render('Patches to active_model_serializers.')).to include('active_model_serializers')
    end

    it 'emits no heading ids, because several records share the same headings' do
      expect(render('## Problem')).not_to include('id=')
    end

    it 'returns an empty safe buffer for a record with no body' do
      expect(render('')).to be_html_safe
      expect(render('')).to eq('')
    end
  end

  describe 'a hostile body' do
    it 'does not let a script tag survive' do
      html = render("<script>alert(1)</script>\n\nAfter.")

      expect(html).not_to include('<script')
      expect(html).to include('<p>After.</p>')
    end

    it 'does not let a javascript URL survive' do
      html = render('[click](javascript:alert(1))')

      expect(html).not_to include('javascript:')
      expect(html).to include('click')
    end

    it 'does not let an event handler survive' do
      expect(render('<img src=x onerror=alert(1)>')).not_to include('<img')
    end

    it 'does not let an iframe survive' do
      expect(render('<iframe src="https://example.invalid"></iframe>')).not_to include('<iframe')
    end

    it 'keeps a link on an allowed protocol' do
      expect(render('[home](https://example.com)')).to include(%(<a href="https://example.com">home</a>))
    end
  end
end
