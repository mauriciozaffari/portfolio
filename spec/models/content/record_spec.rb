require "rails_helper"

RSpec.describe Content::Record do
  def expect_rejection(path, message)
    expect { load_record(path) }.to raise_error(Content::InvalidRecord, message)
  end

  describe "a well-formed record" do
    it "loads, exposes its front matter, and is renderable" do
      record = load_record(write_record("gem-downloads", type: "metric"))

      expect(record.id).to eq("gem-downloads")
      expect(record.type).to eq("metric")
      expect(record.locale).to eq("en")
      expect(record[:label]).to eq("Example")
      expect(record).to be_renderable
    end

    it "renders its body to sanitized HTML" do
      record = load_record(write_record("looper", type: "experience", body: "A **bold** claim."))

      expect(record.html).to include("<strong>bold</strong>")
      expect(record.html).to be_html_safe
    end
  end

  describe "front matter that will not parse" do
    it "rejects a file with no front matter block" do
      path = write_file("en/plain.md", "Just prose, no front matter.\n")

      expect_rejection path, /does not open with a YAML front matter block/
    end

    it "rejects front matter that is not valid YAML" do
      path = write_file("en/broken.md", "---\nid: [unclosed\n---\n\nBody.\n")

      expect_rejection path, /front matter is not valid YAML/
    end

    it "rejects front matter that is not a set of key\/value pairs" do
      path = write_file("en/scalar.md", "---\njust a string\n---\n\nBody.\n")

      expect_rejection path, /front matter is not a set of key\/value pairs/
    end
  end

  describe "keys" do
    Content::Schema::COMMON_KEYS.each do |key|
      it "rejects a record with no `#{key}`" do
        path = write_record("rails-years", type: "metric", **{ key => nil })

        expect_rejection path, /missing the required key `#{key}`/
      end
    end

    it "rejects a record missing a key its own type requires" do
      path = write_record("decisiv", type: "experience", role: nil)

      expect_rejection path, /a `experience` is missing the required key `role`/
    end

    it "rejects a summary in front matter, which belongs in the body" do
      path = write_record("rails-years", type: "metric", summary: "Duplicated prose.")

      expect_rejection path, /carries `summary`, which belongs in the body/
    end
  end

  describe "the type vocabulary" do
    it "rejects a type that is not in the vocabulary" do
      path = write_record("a-testimonial", type: "testimonial")

      expect_rejection path, /`type` is `testimonial`, which is not one of/
    end
  end

  describe "identifiers" do
    it "rejects an id that does not match its filename" do
      path = write_record("metric-one", type: "metric", path: "en/metric-two.md")

      expect_rejection path, /`id` is `metric-one` but the filename says `metric-two`/
    end

    it "rejects an id that is not kebab-case" do
      path = write_record("Rails_Years", type: "metric")

      expect_rejection path, /`id` is `Rails_Years`, which is not kebab-case/
    end
  end

  describe "enumerated values" do
    it "rejects a locale outside the vocabulary" do
      path = write_record("rails-years", type: "metric", locale: "fr")

      expect_rejection path, /`locale` is `fr`, which is not one of en, pt-BR/
    end

    it "rejects a status outside the vocabulary" do
      path = write_record("rails-years", type: "metric", status: "archived")

      expect_rejection path, /`status` is `archived`, which is not one of draft, published/
    end

    it "rejects a confidentiality outside the vocabulary" do
      path = write_record("rails-years", type: "metric", status: "draft", confidentiality: "internal")

      expect_rejection path, /`confidentiality` is `internal`, which is not one of public, restricted/
    end

    it "rejects a prominence outside the vocabulary" do
      path = write_record("decisiv", type: "experience", prominence: "hero")

      expect_rejection path, /`prominence` is `hero`, which is not one of primary, secondary/
    end
  end

  describe "location on disk" do
    it "rejects a record whose locale disagrees with its directory" do
      path = write_record("rails-years", type: "metric", locale: "pt-BR", path: "en/rails-years.md")

      expect_rejection path, /`locale` is `pt-BR` but the file sits under `en`/
    end

    it "rejects a record that is not inside a locale directory" do
      path = write_record("rails-years", type: "metric", path: "rails-years.md")

      expect_rejection path, /is not inside a locale directory/
    end
  end

  describe "bodies" do
    it "rejects a body on a type that is entirely structured" do
      path = write_record("rails-years", type: "metric", body: "Prose that duplicates the front matter.")

      expect_rejection path, /a `metric` is entirely structured, so its body must be empty/
    end

    it "rejects a missing body on a type whose prose is the point" do
      path = write_record("decisiv", type: "experience", body: nil)

      expect_rejection path, /a `experience` carries its prose in the body, and this one has none/
    end
  end

  describe "the published and restricted invariant" do
    it "rejects a record that is both at once" do
      path = write_record("rails-years", type: "metric", status: "published", confidentiality: "restricted")

      expect_rejection path, /is `published` and `restricted` at once/
    end

    it "allows a restricted record that is still a draft" do
      record = load_record(write_record("rails-years", type: "metric", status: "draft", confidentiality: "restricted"))

      expect(record).not_to be_renderable
    end
  end
end
