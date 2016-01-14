#!/bin/sh
case "${1}" in
	(gentoo) ;;
	(*) egencache --jobs=4 --repo="${1}" --update;;
esac
