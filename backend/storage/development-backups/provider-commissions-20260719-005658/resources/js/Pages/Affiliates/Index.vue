<script setup lang="ts">
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import Pagination from '@/Components/Pagination.vue';
import { formatDateTime } from '@/lib/format';
import type { Paginated, VerificationRequest } from '@/types';

const props = defineProps<{
    requests: Paginated<VerificationRequest>;
    filters: { status: string };
    counts: { pending: number; approved: number; rejected: number };
}>();

const tabs = [
    { key: 'pending', label: 'Pendientes', count: props.counts.pending },
    { key: 'approved', label: 'Aprobados', count: props.counts.approved },
    { key: 'rejected', label: 'Rechazados', count: props.counts.rejected },
];

function commissionPercent(rate?: string | number | null): string {
    if (rate === null || rate === undefined) return 'Pendiente';
    return `${(Number(rate) * 100).toFixed(2)}%`;
}

function setStatus(status: string) {
    router.get('/admin/afiliados', { status }, { preserveState: true, replace: true });
}
</script>

<template>
    <Head title="Afiliados" />
    <AdminLayout>
        <template #title>Afiliados</template>

        <!-- Tabs -->
        <div class="mb-4 flex gap-1 rounded-lg bg-white p-1 shadow-sm">
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
                <span
                    class="ml-1 rounded-full px-1.5 text-xs"
                    :class="filters.status === tab.key ? 'bg-sky-500' : 'bg-slate-200'"
                >
                    {{ tab.count }}
                </span>
            </button>
        </div>

        <!-- Tabla -->
        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <table class="min-w-full divide-y divide-slate-100 text-sm">
                <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-5 py-3">Negocio</th>
                        <th class="px-5 py-3">Tipo</th>
                        <th class="px-5 py-3">Comisión</th>
                        <th class="px-5 py-3">Contacto</th>
                        <th class="px-5 py-3">Docs</th>
                        <th class="px-5 py-3">Enviada</th>
                        <th class="px-5 py-3">Estado</th>
                        <th class="px-5 py-3"></th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr
                        v-for="req in requests.data"
                        :key="req.id"
                        class="hover:bg-slate-50"
                    >
                        <td class="px-5 py-3">
                            <p class="font-medium text-slate-800">
                                {{ req.provider?.business_name ?? '—' }}
                            </p>
                            <p class="text-xs text-slate-500">
                                {{ req.provider?.city }}, {{ req.provider?.province }}
                            </p>
                        </td>
                        <td class="px-5 py-3 text-slate-600">
                            {{ req.provider?.business_type?.name ?? '—' }}
                        </td>
                        <td class="px-5 py-3 font-medium text-slate-700">
                            {{ commissionPercent(req.provider?.commission_rate) }}
                        </td>
                        <td class="px-5 py-3">
                            <p class="text-slate-700">{{ req.provider?.user?.name }}</p>
                            <p class="text-xs text-slate-500">{{ req.provider?.user?.email }}</p>
                        </td>
                        <td class="px-5 py-3 text-slate-600">{{ req.documents_count ?? 0 }}</td>
                        <td class="px-5 py-3 text-slate-500">
                            {{ formatDateTime(req.submitted_at) }}
                        </td>
                        <td class="px-5 py-3"><StatusBadge :status="req.status" /></td>
                        <td class="px-5 py-3 text-right">
                            <Link
                                :href="`/admin/afiliados/${req.id}`"
                                class="font-medium text-sky-600 hover:underline"
                            >
                                Revisar
                            </Link>
                        </td>
                    </tr>
                    <tr v-if="!requests.data.length">
                        <td colspan="7" class="px-5 py-10 text-center text-slate-400">
                            No hay solicitudes en esta categoría.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            <Pagination :links="requests.links" />
        </div>
    </AdminLayout>
</template>
