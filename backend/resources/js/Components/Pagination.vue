<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
import type { PaginationLink } from '@/types';

defineProps<{
    links: PaginationLink[];
}>();
</script>

<template>
    <nav v-if="links.length > 3" class="flex flex-wrap items-center gap-1">
        <template v-for="(link, i) in links" :key="i">
            <span
                v-if="link.url === null"
                class="rounded-md px-3 py-1.5 text-sm text-slate-400"
                v-html="link.label"
            />
            <Link
                v-else
                :href="link.url"
                class="rounded-md px-3 py-1.5 text-sm transition"
                :class="
                    link.active
                        ? 'bg-sky-600 text-white'
                        : 'bg-white text-slate-600 hover:bg-slate-100'
                "
                v-html="link.label"
            />
        </template>
    </nav>
</template>
