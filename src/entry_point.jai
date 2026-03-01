Allocators :: struct {
    persistent: *Allocator;
}

main :: () {
    allocators: Allocators;
    prepare_memory_arenas(*allocators);
    parse_md_into_ast(allocators.persistent, "./resources/test.md");
}

prepare_memory_arenas :: (allocators: *Allocators) {
    perm_pool: Flat_Pool;

    persistent: Allocator;
    persistent.proc = flat_pool_allocator_proc;
    persistent.data = *perm_pool;

    allocators.persistent = *persistent;
}

#import "Basic";
#import "Flat_Pool";
#load "md_parser.jai";
