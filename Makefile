# Edit variables below to customize book
booktitle = Fair Representations of Data
booksubtitle =
bookauthors = Oliver Thomas
titlepagemidnote = Incomplete working draft --- DO NOT SHARE
titlepagefootnote = Latest public version available at \url{oliverthomas.ml}
bookpdffilename = book.pdf

# Add all sources that need to compile to some html page
SOURCES := sources/index.md \
           sources/introduction.md \
		   sources/fair_representations.md \
           sources/data_domain_representations.md \
           sources/identifying_those_at_risk.md \
           sources/appendix.md \

# Put everything that should compile into an individual chapter.
CHAPTERS := sources/introduction.md \
			sources/fair_representations.md \
            sources/data_domain_representations.md \
            sources/identifying_those_at_risk.md \
            sources/appendix.md \

# Add all style files you're using.
STYLES := css/tufte.css \
          css/pandoc.css \
          css/pandoc-solarized.css \
          css/numenvs.css \
          css/navbar.css \
          css/index.css \

# DO NOT EDIT BELOW THIS COMMENT

ASSETS := $(wildcard assets/*)

HTMLTARGETS := $(patsubst sources/%.md,docs/%.html,$(SOURCES))

PDFTARGETS := $(patsubst sources/%.md,docs/pdf/%.pdf,$(CHAPTERS))

.PHONY: all
all: html pdf style

html: $(HTMLTARGETS) assets

pdf: docs/pdf/$(bookpdffilename) $(PDFTARGETS)

assets: $(ASSETS)
	cp -R assets docs

style: $(STYLES)
	cat $(STYLES) > docs/style.css;

## Generalized rule: how to build a .html file from each .md
## For technical reasons, this uses two pandoc passes:
## Step 1: Expands citations into markdown footnotes.
## Step 2: Convert preprocessed files to html.
docs/%.html: sources/%.md templates/tufte.html5 $(STYLES) Makefile references.bib
	pandoc \
    --csl=templates/chicago-fullnote-bibliography.csl \
    --bibliography=references.bib \
    --template=templates/page.md \
    -t markdown-citations $< | \
  pandoc \
    --strip-comments \
    --katex \
    --toc-depth=2 \
    --from markdown-markdown_in_html_blocks+raw_html+tex_math_single_backslash \
    --section-divs \
    --table-of-contents \
    --filter ./filters/sidenote.py \
    --filter ./filters/numenvs.py \
    --to html5 \
    --css style.css \
    --variable lang="en" \
    --variable lastupdate="`date -r $<`" \
    --variable references-section-title="References" \
    --template templates/tufte.html5 \
    --output $@; \
  cat $(STYLES) > docs/style.css; \

## Rule to create individual pdf chapters.
## Step 1: Expands citations into markdown footnotes.
## Step 2: Convert preprocessed files to pdf.
docs/pdf/%.pdf: sources/%.md 
	pandoc \
    --csl=templates/chicago-fullnote-bibliography.csl \
    --bibliography=references.bib \
    --template=templates/page.md \
    -t markdown-citations $< | \
  pandoc \
    --filter ./filters/numenvs.py \
    --variable booktitle="${booktitle}" \
    --variable booksubtitle="${booksubtitle}" \
    --variable bookauthors="${bookauthors}" \
    --variable lastupdate="`date -r $< +%Y-%m-%d`" \
    --template templates/chapter.tex \
    --output $@; \

## Rule to create pdf book.
## Step 1: Give each markdown file a chapter heading.
## Step 2: Compile into pdf using pandoc.
docs/pdf/$(bookpdffilename): $(SOURCES) templates/book.tex Makefile references.bib
	$(foreach chapter,$(CHAPTERS),\
      pandoc --template templates/chapter.md $(chapter) \
      --id-prefix=$(notdir $(chapter)) \
      --output tmp-$(notdir $(chapter));) \
  pandoc \
    --filter filters/numenvs.py \
    --bibliography=references.bib \
    --csl=templates/chicago-fullnote-bibliography.csl \
    --template templates/book.tex \
    --variable lastupdate="`date`" \
    --variable booktitle="${booktitle}" \
    --variable booksubtitle="${booksubtitle}" \
    --variable bookauthors="${bookauthors}" \
    --variable titlepagemidnote="${titlepagemidnote}" \
    --variable titlepagefootnote="${titlepagefootnote}" \
    --output docs/pdf/$(bookpdffilename) \
    $(foreach chapter,$(CHAPTERS),tmp-$(notdir $(chapter))) sources/references.md; \
  $(foreach chapter,$(CHAPTERS),rm tmp-$(notdir $(chapter));) \

