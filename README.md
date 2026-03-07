# Tabula-SSG

A static site generator written in Jai.

### Features

Tabula operates on a subset of the [commonmark markdown specification](https://spec.commonmark.org/0.31.2/). I have not implemented the full specification, rather the features which I tend to use in my blog posts. Until I have reason to implement more, or receive OSS contributions, these are:

- ATX Headings.
- Singular inline emphasis (bold, italic, bolditalic).
- Regular text & newlines.
- Single-line quotes.
- Multi-line quotes.
- Inline code.
- Code blocks.
- Hyperlinks.
- Images.

### Usage

First, download `tabula.exe` or build from source by cloning the repository and running `jai build.jai`. 

In the same directory as `tabula.exe`, create a folder called `posts`. In this folder, you can put any `.md` files you want to turn into blog posts.

In the `posts` folder, you can also make an `images` subfolder, to store local images you reference in those posts.

If you then run `tabula.exe`, a `web` folder will be created. This should host all of the necessary files for you to host your static site. You can test this out by entering the `web` folder and running this python command: `python3 -m http.server`.

Visiting `localhost:port` from your website will then present the website.

Important note: all `.md` files you wish to parse must begin with a custom [front matter](https://jekyllrb.com/docs/front-matter/). 

The front matter must contain 3 pieces of metadata. These are title, subtitle, and date (YYYY-MM-DD). Title is the only required field.

I've left an example in the provided `test.md` file, but for completeness:

```
---
title: My blog post
subtitle: A blog post about blog posts
date: 2025-06-03
---
```

Or you could do:

```
---
title: My blog post
date: 2025-06-03
---
```

and so on.

There are a number of command line arguments you can supply:

```
Usage: tabula [options]

Options:
  --title <text>        Site title displayed in the header
  --stylesheet <path>   Path to a custom CSS file
  --about <path>        Path to a markdown file to use as the about page. This page does not need frontmatter.
  --no-about            Disable the about page entirely
  --help                Show this message
```

### Contributions

To contribute to this project, you'll need to have access to the [Jai](https://en.wikipedia.org/wiki/Jai_(programming_language)) compiler.

The process is simple; if you find a bug, raise an issue on GitHub or git.deplet.ing. If you submit a PR, I'll try to check it out promptly.

### Example Sites:

[Working on it!]()

### Note 

Untested outside of Windows 10 - may find bugs with line endings etc.



