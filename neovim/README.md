# Neovim queries

These queries are derived from `nvim-treesitter/nvim-treesitter`, commit
`29212d826054bb2948fa9d3a99eca9bf6a050eb2`,
`runtime/queries/latex/{highlights,folds,injections}.scm`.
They retain that project's Apache-2.0 license; see `LICENSE` here.
The grammar remains MIT-licensed under the repository's root `LICENSE`.

This fork changes `highlights.scm` to:

- Capture each math delimiter field in a separate pattern to reduce query
  compilation cost while preserving delimiter captures.
- Give `@markup.math` priority 90, below specific token captures at 100.
- Give braces in `curly_group_path` priority 110, above whole-path captures.

The folds and injection queries are unchanged apart from provenance comments.
The files live in `neovim/queries/latex/` so the Tree-sitter CLI does not load
Neovim-specific directives as portable CLI highlighting queries.
These queries use Neovim predicates, captures and metadata.
For toolchain-tools.nvim, set `parser.queries = "neovim/queries/latex"` so the parser and
queries are installed from the same pinned fork revision.

Run the capture, metadata and malformed-input checks against a built parser:

```sh
tree-sitter build -o /tmp/latex-query-test.so
LATEX_TEST_PARSER=/tmp/latex-query-test.so nvim --headless -u NONE -i NONE -l test/queries.lua
```

The test also prints compilation times for the upstream and fork queries;
timings are diagnostic, with no environment-dependent threshold.
