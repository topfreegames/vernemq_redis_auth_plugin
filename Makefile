.PHONY: test

prod:
	@MIX_ENV=prod mix release --env=prod
test:
	@mix test
clean:
	@mix clean
	@rm -rf _build
