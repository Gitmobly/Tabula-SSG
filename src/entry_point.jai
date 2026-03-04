Allocators :: struct {
    persistent: *Allocator;
}

main :: () {
    perm_pool: Flat_Pool;

    persistent: Allocator;
    persistent.proc = flat_pool_allocator_proc;
    persistent.data = *perm_pool;

    allocators: Allocators;
    allocators.persistent = *persistent;

    file_path := "./resources/test.md"; // Will be a bunch eventually
    ok, lexer_result := run_markdown_lexer(allocators.persistent, "./resources/test.md");
    if (!ok) print("Failed to complete lexer stage for file: %\n", file_path);
    run_markdown_parser(allocators.persistent, lexer_result);
}

#import "Basic";
#import "Flat_Pool";
#load "md_parser.jai";
