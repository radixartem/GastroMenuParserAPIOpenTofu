TOFU := tofu
DIR  := live/production

.PHONY: fmt init validate plan apply

fmt:
	$(TOFU) fmt -recursive

init:
	cd $(DIR) && $(TOFU) init -backend-config=backend.hcl

validate:
	cd $(DIR) && $(TOFU) validate

plan:
	cd $(DIR) && $(TOFU) plan

apply:
	cd $(DIR) && $(TOFU) apply