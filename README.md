# tree-sitter-latex

[![CI](https://github.com/latex-lsp/tree-sitter-latex/workflows/CI/badge.svg)](https://github.com/latex-lsp/tree-sitter-latex/actions)
[![npm](https://img.shields.io/npm/v/@pfoerster/tree-sitter-latex)](https://www.npmjs.com/package/@pfoerster/tree-sitter-latex)

This repo provides a [LaTeX](https://www.latex-project.org/) grammar for the [tree-sitter](https://github.com/tree-sitter/tree-sitter) parser generator.

Originally, this grammar is based off the parser of the [`texlab`](https://github.com/latex-lsp/texlab) language server and primarily focuses on the constructs that are relevant for the language server.

This fork bundles Neovim highlighting, folding and injection queries in
[`neovim/`](neovim/README.md), derived from a pinned nvim-treesitter revision.
The queries include delimiter compilation and highlight priority fixes, so consumers
can use the parser and queries together without runtime query rewrites.
The grammar is MIT-licensed; the bundled queries are Apache-2.0-licensed.

To generate the parser, run

```
npx tree-sitter generate
```

after checking out the repository.

## Limitations

As widely known, parsing LaTeX is Turing complete so there is no way to handle every construct in a `tree-sitter` grammar. Instead, the grammar relies on a best effort approach while focusing on the LaTeX specific constructs like environments or sections instead of dealing with TeX internals like catcode.
