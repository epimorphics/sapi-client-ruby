.PHONY: auth clean gem publish test

NAME?=sapi-client-ruby
OWNER?=epimorphics
VERSION?=$(shell ruby -e 'require "./lib/sapi_client/version" ; puts SapiClient::VERSION')
PAT?=$(shell read -p 'Github access token:' TOKEN; echo $$TOKEN)

AUTH=${HOME}/.gem/credentials
GEM=${NAME}-${VERSION}.gem
GPR=https://rubygems.pkg.github.com/${OWNER}
SPEC=${NAME}.gemspec

all: publish

${AUTH}:
	@mkdir -p ${HOME}/.gem
	@echo '---' > ${AUTH}
	@echo ':github: Bearer ${PAT}' >> ${AUTH}
	@chmod 0600 ${AUTH}

${GEM}: ${SPEC} ./lib/sapi_client/version.rb
	gem build ${SPEC}

auth: ${AUTH}

setup:
	@bundle install

build: gem

gem: ${GEM}
	@echo ${GEM}

lint: gem
	@rubocop

test: gem setup
	@rake test

publish: ${GEM} ${AUTH}
	@echo Publishing package ${NAME}:${VERSION} to ${OWNER} ...
	@gem push --key github --host ${GPR} ${GEM}
	@echo Done.

clean:
	@rm -rf ${GEM}

realclean: clean
	@rm -rf ${AUTH}

console:
	@ruby -I . bin/console
