# Update via dnssec

Publish a DNSSEC record of a git repo! Ensure a checkout or clone is up-to-date with that record. That's it!

## Motivation

DNSSEC gives us simple way to publish a signed fact. Using that knowledge coupled with the awesomeness of git,
you can use git as a tamper-proof distribution method for source code (in so far as you trust DNSSEC).

## Usage

To update a directory pinned to a record published via DNSSEC

    ./update.sh update_via_dnssec.slick.io some-dir master

To generate the needed DNSSEC records from a git repo

    ./generate.rb update_via_dnssec.slick.io. https://github.com/joshbuddy/update_via_dnssec [...more origins] master:sha-1 [branch:other-sha-1]

... and add those records signed with dnssec!

## How it works

    ./checkout.sh _gitdnssec0.update_via_dnssec.slick.io some-dir master

This will ensure that checkout_via_dnssec will be brought up-to-date with whatever information is provided in the TXT record at `_gitdnssec0.update_via_dnssec.slick.io`. The txt record is in the following format

    v=uvd1 o=host,host,host b=sha1

    `v` version: currently uvd1
    `o` origins: a comma-seperated list of origins. must include protocol
    `b` branch: a comma-seperated list of name, sha1 tuple delimited by `:`.
    `c` continue: a flag indicated the dns record coninutes in the next index

All dns records must be published relative to a host. The TXT records will be prepended with `_gitdnssec{i}`, where `i` starts at 0 and goes to 9, never skipping a number. Values above 0 are optional and only used to extend the record. As DNS generally doesn't want us to publish a book there, we only go to 9 (cuz ten hops is good enough for SPF).

We can generate those records with

    ./generate.rb update_via_dnssec.slick.io. https://github.com/joshbuddy/update_via_dnssec master:4405203fb68e3233e7aa0b2b8ab48fd65ee2a560

Which will output

    To publish origins https://github.com/joshbuddy/update_via_dnssec with branches master, 4405203fb68e3233e7aa0b2b8ab48fd65ee2a560 add the following DNS records:

    _gitdnssec0.update_via_dnssec.slick.io. 600 IN TXT "v=uvd1 o=https://github.com/joshbuddy/update_via_dnssec b=master:RAUgP7aOMjPnqgsrirSP1l7ipWA="