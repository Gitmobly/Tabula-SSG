/* TODO(JJB): How personalisable should this be? For now, not at all... until I come up with an idea*/
create_css_stylesheet :: () -> bool {
    success := write_entire_file("./web/styles.css", DEFAULT_CSS);
    if (!success) {
        print("Could not css write to file.\n");
        return false;
    }

    print("Successfully generated styles.css.\n");
    return true;
}

DEFAULT_CSS: string = #string END
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
    background: #fff;
    color: #111;
    font-family: Georgia, serif;
    font-size: 18px;
    line-height: 1.7;
}

header {
    border-bottom: 1px solid #ddd;
    padding: 1rem 2rem;
}

header nav {
    max-width: 660px;
    margin: 0 auto;
    display: flex;
    align-items: baseline;
    gap: 2rem;
}

header .site-title {
    font-size: 1rem;
    font-weight: 700;
    margin-right: auto;
}

header a {
    font-family: 'Courier New', monospace;
    font-size: 0.8rem;
    color: #111;
    text-decoration: none;
    letter-spacing: 0.04em;
}

header a:hover { text-decoration: underline; }

main {
    max-width: 660px;
    margin: 0 auto;
    padding: 3rem 1.5rem 8rem;
}

h1, h2, h3, h4, h5, h6 {
    font-family: Georgia, serif;
    line-height: 1.25;
    margin: 2.5em 0 0.5em;
    color: #000;
}

h1 { font-size: 2.2rem; margin-top: 0; border-bottom: 2px solid #000; padding-bottom: 0.3em; }
h2 { font-size: 1.5rem; }
h3 { font-size: 1.2rem; font-style: italic; font-weight: normal; }
h4 { font-size: 1rem;   font-style: italic; color: #444; }
h5 { font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.08em; color: #444; }
h6 { font-size: 0.8rem;  color: #888; }

p { margin-bottom: 1.4em; }

strong { font-weight: 700; }
em     { font-style: italic; }

blockquote {
    margin: 2em 0;
    padding: 0.8em 1.4em;
    border-left: 3px solid #000;
    color: #444;
    font-style: italic;
}

code {
    font-family: 'Courier New', monospace;
    font-size: 0.82em;
    background: #f4f4f4;
    padding: 0.1em 0.4em;
    border-radius: 3px;
}

pre {
    background: #f4f4f4;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 1.4em;
    overflow-x: auto;
    margin: 2em 0;
}

pre code { background: none; padding: 0; font-size: 0.85rem; }

footer {
    margin-top: 6rem;
    padding-top: 1.5rem;
    border-top: 1px solid #ddd;
    font-size: 0.78rem;
    color: #888;
    font-family: 'Courier New', monospace;
}

@media (max-width: 480px) {
    body              { font-size: 16px; }
    main              { padding: 2rem 1.5rem 5rem; }
    h1                { font-size: 1.8rem; }
    header            { padding: 1rem 1.5rem; }
    header nav        { gap: 1.2rem; }
}
END
