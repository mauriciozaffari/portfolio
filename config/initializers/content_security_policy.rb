# Be sure to restart your server when you modify this file.

# This page ships zero JavaScript (see features/landing-page/IMPLEMENTATION.md),
# which means the policy below can be the strict one that is usually only
# aspirational: `script-src 'none'`, with no `unsafe-inline` anywhere and no
# nonce machinery to get wrong.
#
# Everything starts denied. Each directive that opens up is opened because a
# byte on the page needs it, and nothing else is.
Rails.application.configure do
  config.content_security_policy do |policy|
    # Deny by default. Every fetch directive not named below inherits this,
    # which covers connect-src, font-src, media-src, manifest-src, and worker-src.
    policy.default_src :none

    # One first-party stylesheet, compiled by Tailwind and served by Propshaft.
    policy.style_src :self

    # The two favicons and the apple-touch-icon, all first-party.
    policy.img_src :self

    # The page has no script tag. Not `:self` — there is nothing to allow, and
    # a policy that permits what the page does not use is a policy that will
    # not notice when the page changes.
    policy.script_src :none

    # No plugins, no <base> tag, no forms, and never framed.
    policy.object_src :none
    policy.base_uri :none
    policy.form_action :none
    policy.frame_ancestors :none
  end

  # No nonce generator. Nonces exist to permit inline script and inline style;
  # this application has neither, and generating one would mean touching the
  # session on a page that otherwise has no reason to.
  #
  # Not report-only. There is no violation-report endpoint to send to — error
  # monitoring is explicitly out of scope in features/deployment/SPEC.md — so
  # the policy is enforced or it is decoration.
end
