<script setup lang="ts">
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import Pagination from '@/Components/Pagination.vue';
import { formatMoney } from '@/lib/format';
import type { Paginated, Experience } from '@/types';

const props = defineProps<{
    experiences: Paginated<Experience>;
    filters: { search: string; active: string; status: string };
}>();

const search = ref(props.filters.search);

let timeout: ReturnType<typeof setTimeout>;
watch(search, (value) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => {
        router.get(
            '/admin/experiencias',
            { ...props.filters, search: value },
            { preserveState: true, replace: true },
        );
    }, 350);
});

function setFilter(key: 'active' | 'status', value: string) {
    router.get(
        '/admin/experiencias',
        { ...props.filters, [key]: value },
        { preserveState: true, replace: true },
    );
}
</script>

<template>
    <Head title="Experiencias" />
    <AdminLayout>
        <template #title>Experiencias</template>

        <!-- Filtros -->
        <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
            <input
                v-model="search"
                type="search"
                placeholder="Buscar por título, lugar o provincia…"
                class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500 sm:max-w-xs"
            />
            <select
                :value="filters.active"
                class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500"
                @change="setFilter('active', ($event.target as HTMLSelectElement).value)"
            >
                <option value="all">Todas (activas e inactivas)</option>
                <option value="active">Solo activas</option>
                <option value="inactive">Solo desactivadas</option>
            </select>
            <select
                :value="filters.status"
                class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500"
                @change="setFilter('status', ($event.target as HTMLSelectElement).value)"
            >
                <option value="all">Cualquier estado</option>
                <option value="published">Publicada</option>
                <option value="paused">Pausada</option>
                <option value="draft">Borrador</option>
                <option value="rejected">Rechazada</option>
            </select>
        </div>

        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <table class="min-w-full divide-y divide-slate-100 text-sm">
                <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-5 py-3">Experiencia</th>
                        <th class="px-5 py-3">Afiliado</th>
                        <th class="px-5 py-3">Precio</th>
                        <th class="px-5 py-3">Reservas</th>
                        <th class="px-5 py-3">Estado</th>
                        <th class="px-5 py-3">Activa</th>
                        <th class="px-5 py-3"></th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="exp in experiences.data" :key="exp.id" class="hover:bg-slate-50">
                        <td class="px-5 py-3">
                            <p class="font-medium text-slate-800">{{ exp.title }}</p>
                            <p class="text-xs text-slate-500">
                                {{ exp.location }}<span v-if="exp.province">, {{ exp.province }}</span>
                            </p>
                        </td>
                        <td class="px-5 py-3 text-slate-600">{{ exp.provider?.business_name ?? '—' }}</td>
                        <td class="px-5 py-3 text-slate-600">
                            {{ formatMoney(exp.price, exp.currency ?? 'DOP') }}
                        </td>
                        <td class="px-5 py-3 text-slate-600">{{ exp.bookings_count ?? 0 }}</td>
                        <td class="px-5 py-3"><StatusBadge :status="exp.status" /></td>
                        <td class="px-5 py-3">
                            <span
                                class="inline-flex h-2.5 w-2.5 rounded-full"
                                :class="exp.is_active ? 'bg-emerald-500' : 'bg-rose-500'"
                                :title="exp.is_active ? 'Activa' : 'Desactivada'"
                            />
                        </td>
                        <td class="px-5 py-3 text-right">
                            <Link
                                :href="`/admin/experiencias/${exp.id}`"
                                class="font-medium text-sky-600 hover:underline"
                            >
                                Gestionar
                            </Link>
                        </td>
                    </tr>
                    <tr v-if="!experiences.data.length">
                        <td colspan="7" class="px-5 py-10 text-center text-slate-400">
                            No se encontraron experiencias.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            <Pagination :links="experiences.links" />
        </div>
    </AdminLayout>
</template>
