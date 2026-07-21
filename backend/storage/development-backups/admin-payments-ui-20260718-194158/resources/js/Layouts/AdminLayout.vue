<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { Link, usePage, router } from '@inertiajs/vue3';
import type { PageProps } from '@/types';

const page = usePage<PageProps>();
const user = computed(() => page.props.auth.user);

// --- Flash messages ---
const flashMessage = ref<{ type: 'success' | 'error'; text: string } | null>(null);

watch(
    () => page.props.flash,
    (flash) => {
        if (flash?.success) {
            flashMessage.value = { type: 'success', text: flash.success };
        } else if (flash?.error) {
            flashMessage.value = { type: 'error', text: flash.error };
        }
        if (flashMessage.value) {
            setTimeout(() => (flashMessage.value = null), 4000);
        }
    },
    { immediate: true, deep: true },
);

const nav = [
    { label: 'Dashboard', href: '/admin', match: /^\/admin\/?$/ },
    { label: 'Afiliados', href: '/admin/afiliados', match: /^\/admin\/afiliados/ },
    { label: 'Reclamos', href: '/admin/reclamos', match: /^\/admin\/reclamos/ },
    { label: 'Experiencias', href: '/admin/experiencias', match: /^\/admin\/experiencias/ },
];

const currentPath = computed(() => page.url.split('?')[0]);

function isActive(match: RegExp): boolean {
    return match.test(currentPath.value);
}

function logout() {
    router.post('/admin/logout');
}

const mobileOpen = ref(false);
</script>

<template>
    <div class="min-h-screen lg:flex">
        <!-- Sidebar -->
        <aside
            class="fixed inset-y-0 left-0 z-40 w-64 transform bg-slate-900 text-slate-300 transition-transform lg:static lg:translate-x-0"
            :class="mobileOpen ? 'translate-x-0' : '-translate-x-full'"
        >
            <div class="flex h-16 items-center gap-2 px-6">
                <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-sky-500 font-bold text-white">
                    A
                </div>
                <span class="text-lg font-semibold text-white">AndanDO</span>
                <span class="ml-1 rounded bg-slate-700 px-1.5 py-0.5 text-[10px] uppercase tracking-wide">
                    admin
                </span>
            </div>

            <nav class="mt-4 space-y-1 px-3">
                <Link
                    v-for="item in nav"
                    :key="item.href"
                    :href="item.href"
                    class="block rounded-lg px-3 py-2 text-sm font-medium transition"
                    :class="
                        isActive(item.match)
                            ? 'bg-slate-800 text-white'
                            : 'text-slate-400 hover:bg-slate-800/60 hover:text-white'
                    "
                    @click="mobileOpen = false"
                >
                    {{ item.label }}
                </Link>
            </nav>
        </aside>

        <!-- Overlay móvil -->
        <div
            v-if="mobileOpen"
            class="fixed inset-0 z-30 bg-slate-900/50 lg:hidden"
            @click="mobileOpen = false"
        />

        <!-- Contenido -->
        <div class="flex min-h-screen flex-1 flex-col">
            <header class="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-4 lg:px-8">
                <button
                    class="rounded-lg p-2 text-slate-500 hover:bg-slate-100 lg:hidden"
                    @click="mobileOpen = true"
                >
                    ☰
                </button>

                <h1 class="text-sm font-medium text-slate-500 lg:text-base">
                    <slot name="title">Panel administrativo</slot>
                </h1>

                <div class="flex items-center gap-3">
                    <div class="hidden text-right sm:block">
                        <p class="text-sm font-medium text-slate-700">{{ user?.name }}</p>
                        <p class="text-xs text-slate-400">{{ user?.email }}</p>
                    </div>
                    <button
                        class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-50"
                        @click="logout"
                    >
                        Salir
                    </button>
                </div>
            </header>

            <!-- Flash -->
            <div
                v-if="flashMessage"
                class="mx-4 mt-4 rounded-lg px-4 py-3 text-sm lg:mx-8"
                :class="
                    flashMessage.type === 'success'
                        ? 'bg-emerald-50 text-emerald-800'
                        : 'bg-rose-50 text-rose-800'
                "
            >
                {{ flashMessage.text }}
            </div>

            <main class="flex-1 p-4 lg:p-8">
                <slot />
            </main>
        </div>
    </div>
</template>
