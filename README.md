# Usher Web

<p>
  <a href="https://hex.pm/packages/usher_web">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/usher_web.svg">
  </a>
  <a href="https://hexdocs.pm/usher_web">
    <img src="https://img.shields.io/badge/docs-hexdocs-blue" alt="HexDocs">
  </a>
  <a href="https://github.com/typhoonworks/usher_web/actions">
    <img alt="CI Status" src="https://github.com/typhoonworks/usher_web/workflows/ci/badge.svg">
  </a>
</p>

Usher Web is a web interface for the [Usher invitation link management library](https://github.com/typhoonworks/usher).

## Current Features

- List, copy, edit, and delete invitation links.
- Create invitation links with custom names and expiration dates (including perpetual links).

## What's planned?

- Usher provides additional features that are not yet supported in Usher Web:
  - [ ] Custom attributes per token
  - [ ] Signed tokens
  - [ ] Custom tokens (i.e. you can provide your own token slug)
  - [ ] Usage tracking
- [ ] View usage statistics for each invitation link. If you need this right now, you can query usage statistics directly from the database using [Lotus Web](https://github.com/typhoonworks/lotus_web).

## Getting Started

Take a look at the [overview guide](https://hexdocs.pm/usher_web/overview.html) for a quick introduction to Usher Web.
