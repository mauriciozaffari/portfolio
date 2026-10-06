# Concise resume

`mauricio-zaffari-resume.pdf` is the reviewed two-page English resume served at
`/resume-short.pdf`. The full record-derived profiles remain at `/resume.pdf`
and `/pt-BR/resume.pdf`.

The resume deliberately spells out `Ruby on Rails & AI Systems` for recruiter
keyword matching. The site headline uses `Rails & AI Systems` to fit the share
card. These are presentation variants, not different role or skill claims.

## Updating

1. Edit the private resume source outside version control. Check every changed
   fact against `data/en/`; do not copy private source material into this tree.
2. Build the single-column Letter PDF at 10pt body size or larger. Disable font
   ligatures so contact addresses and keywords extract correctly.
3. Remove the phone, private-individual names, compensation and award details.
4. Set only Title, Author, Subject, Creator and Producer metadata. Creator and
   Producer are the canonical host, not the authoring software.
5. Replace this PDF, run `bin/ci`, and visually inspect both pages before commit.

The request specs scan extracted text and metadata, assert two Letter pages,
check selected facts and contact links, and exercise the download. They cannot
prove all prose is current or identify every private name. A content change
requires human review of this file, even if CI stays green.

The application serves this committed file through a controller, not a public
asset URL. No browser, Python or authoring software runs in production.
