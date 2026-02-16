#!/bin/bash

# macOS specifics: see https://github.com/apple/container/blob/main/docs/tutorial.md

sudo container system dns create container
container system property set dns.domain container
