# This Makefile contains rules for making the build/jekyll directory, i.e. copies asciidoc and creates autogenerated files

AUTO_NINJABUILD = $(BUILD_DIR)/auto_jekyll.ninja
ASCIIDOC_INCLUDES_DIR = $(BUILD_DIR)/adoc_includes

# The $(JEKYLL_MARKER_FILE) is used to ensure that all the asciidoc files are copied before we try invoking jekyll
jekyll: | $(JEKYLL_MARKER_FILE)

clean_jekyll:
	rm -rf $(ASCIIDOC_BUILD_DIR)
	rm -f $(AUTO_NINJABUILD)
	rm -f $(HTML_MARKER_FILE)

# Some of the source-files have changed, so things might need to be rebuilt
invalidate_jekyll:
	rm -f $(AUTO_NINJABUILD) $(JEKYLL_MARKER_FILE)

.PHONY: jekyll clean_jekyll invalidate_jekyll

$(ASCIIDOC_BUILD_DIR):
	mkdir -p $@

$(ASCIIDOC_BUILD_DIR)/%: | $(JEKYLL_ASSETS_DIR)/% $(ASCIIDOC_BUILD_DIR)
	cp -r $(firstword $|) $@

JEKYLL_DIRS = $(ASCIIDOC_BUILD_DIR)/_data $(ASCIIDOC_BUILD_DIR)/_layouts $(ASCIIDOC_BUILD_DIR)/_includes $(ASCIIDOC_BUILD_DIR)/_plugins $(ASCIIDOC_BUILD_DIR)/css $(ASCIIDOC_BUILD_DIR)/scripts

$(AUTO_NINJABUILD): $(SCRIPTS_DIR)/create_jekyll_ninjabuild.py $(DOCUMENTATION_INDEX) | $(BUILD_DIR)
	$< $(DOCUMENTATION_INDEX) $(SITE_CONFIG) $(ASCIIDOC_DIR) $(ASCIIDOC_BUILD_DIR) $(ASCIIDOC_INCLUDES_DIR) $@

$(ASCIIDOC_BUILD_DIR)/_data/index.json: $(SCRIPTS_DIR)/create_output_index_json.py $(DOCUMENTATION_INDEX) | $(ASCIIDOC_BUILD_DIR)/_data
	$< $(DOCUMENTATION_INDEX) $@

$(ASCIIDOC_BUILD_DIR)/.htaccess: $(SCRIPTS_DIR)/create_htaccess.py $(HTACCESS_EXTRA) $(wildcard $(DOCUMENTATION_REDIRECTS_DIR)/*.csv) | $(ASCIIDOC_BUILD_DIR)
	$< $(HTACCESS_EXTRA) $(DOCUMENTATION_REDIRECTS_DIR) $@

$(ASCIIDOC_BUILD_DIR)/DO_NOT_EDIT.txt: | $(ASCIIDOC_BUILD_DIR)
	echo "Do not edit any files in this directory. Everything will get overwritten when you run 'make'" > $@

$(ASCIIDOC_BUILD_DIR)/images: | $(ASCIIDOC_BUILD_DIR)
	mkdir -p $@

$(ASCIIDOC_BUILD_DIR)/images/%: $(DOCUMENTATION_IMAGES_DIR)/% | $(ASCIIDOC_BUILD_DIR)/images
	cp $< $@

$(JEKYLL_MARKER_FILE): $(AUTO_NINJABUILD) $(JEKYLL_DIRS) $(ASCIIDOC_BUILD_DIR)/_data/index.json $(ASCIIDOC_BUILD_DIR)/.htaccess $(ASCIIDOC_BUILD_DIR)/DO_NOT_EDIT.txt $(ASCIIDOC_BUILD_DIR)/images/opensocial.png | $(ASCIIDOC_BUILD_DIR)
	ninja -f $<
	touch $@
	rm -f $(HTML_MARKER_FILE)
