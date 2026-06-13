<script setup lang="ts">
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import Pagination from '@/Components/Pagination.vue';
import { formatDateTime } from '@/lib/format';
import type { Paginated, Claim } from '@/types';

const props = defineProps<{
    claims: Paginated<Claim>;
    filters: { status: string };
    counts: { open: number; resolved: number; rejected: number };
}>();

const tabs = [
    { key: 'all', label: 'Todos', count: props.claims.total },
    { key: 'pending', label: 'Pendientes', count: props.counts.open },
    { key: 'resolved', label: 'Resueltos', count: props.counts.resolved },
    { key: 'rejected', label: 'Rechazados', count: props.counts.rejected },
];

function setStatus(status: string) {
    router.get('/admin/reclamos', { status }, { preserveState: true, replace: true });
}
</script>

<template>
    <Head title="Reclamos" />
    <AdminLayout>
        <template #title>Reclamos</template>

        <div class="mb-4 flex flex-wrap gap-1 rounded-lg bg-white p-1 shadow-sm">
            <button
                v-for="tab in tabs"
                :key="tab.key"
                class="flex-1 rounded-md px-3 py-2 text-sm font-medium transition"
                :class="
                    filters.status === tab.key
                        ? 'bg-sky-600 text-white'
                        : 'text-slate-600 hover:bg-slate-100'
                "
                @click="setStatus(tab.key)"
            >
                {{ tab.label }}
            </button>
        </div>

        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <table class="min-w-full divide-y divide-slate-100 text-sm">
                <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-5 py-3">Motivo</th>
                        <th class="px-5 py-3">Experiencia</th>
                        <th class="px-5 py-3">Afiliado</th>
                        <th class="px-5 py-3">Cliente</th>
                        <th class="px-5 py-3">Fecha</th>
                        <th class="px-5 py-3">Estado</th>
                        <th class="px-5 py-3"></th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="claim in claims.data" :key="claim.id" class="hover:bg-slate-50">
                        <td class="px-5 py-3 font-medium text-slate-800">{{ claim.reason }}</td>
                        <td class="px-5 py-3 text-slate-600">
                            {{ claim.booking?.experience?.title ?? '—' }}
                        </td>
                        <td class="px-5 py-3 text-slate-600">
                            {{ claim.provider?.business_name ?? '—' }}
                        </td>
                        <td class="px-5 py-3 text-slate-600">{{ claim.user?.name ?? '—' }}</td>
                        <td class="px-5 py-3 text-slate-500">{{ formatDateTime(claim.created_at) }}</td>
                        <td class="px-5 py-3"><StatusBadge :status="claim.status" /></td>
                        <td class="px-5 py-3 text-right">
                            <Link
                                :href="`/admin/reclamos/${claim.id}`"
                                class="font-medium text-sky-600 hover:underline"
                            >
                                Ver
                            </Link>
                        </td>
                    </tr>
                    <tr v-if="!claims.data.length">
                        <td colspan="7" class="px-5 py-10 text-center text-slate-400">
                            No hay reclamos en esta categoría.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            <Pagination :links="claims.links" />
        </div>
    </AdminLayout>
</template>
