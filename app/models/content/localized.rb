module Content
  # A record chosen for a requested locale, together with whether it had to be
  # borrowed from another one.
  #
  # A view needs both facts: the notice it shows the reader, and the language to
  # put on the container's lang attribute, so that a screen reader switches
  # voice rather than mispronouncing the text.
  Localized = Data.define(:record, :requested_locale) do
    def substituted?
      record.locale != requested_locale
    end

    def language
      record.locale
    end
  end
end
