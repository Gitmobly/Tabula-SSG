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

    run_markdown_lexer(allocators.persistent, "./resources/test.md");
}

#import "Basic";
#import "Flat_Pool";
#load "md_parser.jai";
