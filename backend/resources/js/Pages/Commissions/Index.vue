<script setup lang="ts">
// AndanDO Provider Commissions Module
import { reactive, ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime } from '@/lib/format';

interface ProviderRow {
    id: number;
    business_name: string;
    rnc?: string | null;
    city?: string | null;
    province?: string | null;
    status: string;
    commission_rate?: string | number | null;
    user?: { id: number; name: string; email?: string | null } | null;
    latest_commission_change?: {
        id: number;
        old_rate?: string | number | null;
        new_rate: string | number;
        created_at?: string | null;
        changed_by?: { id: number; name: string; email?: string | null } | null;
    } | null;
}

interface PaginationLink { url: string | null; label: string; active: boolean }
interface Paginated<T> { data: T[]; links: PaginationLink[]; total: number }

const props = defineProps<{
    providers: Paginated<ProviderRow>;
    filters: { search: string; status: string };
    defaultCommissionPercent: number;
}>();

const filters = reactive({ ...props.filters });
const commissionValues = reactive<Record<number, number>>(
    Object.fromEntries(
        props.providers.data.map((provider) => [
            provider.id,
            provider.commission_rate === null || provider.commission_rate === undefined
                ? props.defaultCommissionPercent
                : Number(provider.commission_rate) * 100,
        ]),
    ),
);
const processingId = ref<number | null>(null);

function applyFilters() {
    router.get('/admin/comisiones', { ...filters }, { preserveState: true, replace: true });
}

function resetFilters() {
    Object.assign(filters, { search: '', status: 'all' });
    applyFilters();
}

function percentLabel(rate?: string | number | null): string {
    if (rate === null || rate === undefined) return 'Sin asignar';
    return `${(Number(rate) * 100).toFixed(2)}%`;
}

function save(provider: ProviderRow) {
    const value = Number(commissionValues[provider.id]);

    if (!Number.isFinite(value) || value < 0 || value > 100) {
        window.alert('La comisión debe estar entre 0% y 100%.');
        return;
    }

    processingId.value = provider.id;
    router.patch(
        `/admin/comisiones/${provider.id}`,
        { commission_percent: value },
        {
            preserveScroll: true,
            onFinish: () => { processingId.value = null; },
        },
    );
}
</script>

<template>
    <Head title="Comisiones" />
    <AdminLayout>
        <template #title>Comisiones por afiliado</template>

        <div class="mb-5 rounded-xl border border-sky-100 bg-sky-50 p-4 text-sm text-sky-800">
            La comisión configurada se aplicará solamente a reservas y transacciones nuevas.
            Los pagos históricos conservan la tasa con la que fueron creados.
        </div>

        <form class="mb-5 rounded-xl bg-white p-4 shadow-sm" @submit.prevent="applyFilters">
            <div class="grid gap-3 md:grid-cols-[minmax(0,1fr)_220px_auto]">
                <input
                    v-model="filters.search"
                    type="search"
                    placeholder="Buscar negocio, RNC, contacto o correo..."
                    class="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-sky-500"
                />
                <select v-model="filters.status" class="rounded-lg border border-slate-200 px-3 py-2 text-sm">
                    <option value="all">Aprobados y suspendidos</option>
                    <option value="approved">Aprobados</option>
                    <option value="suspended">Suspendidos</option>
                </select>
                <div class="flex gap-2">
                    <button type="submit" class="rounded-lg bg-sky-600 px-4 py-2 text-sm font-medium text-white hover:bg-sky-700">Filtrar</button>
                    <button type="button" class="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50" @click="resetFilters">Limpiar</button>
                </div>
            </div>
        </form>

        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                    <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                            <th class="px-5 py-3">Afiliado</th>
                            <th class="px-5 py-3">Contacto</th>
                            <th class="px-5 py-3">Estado</th>
                            <th class="px-5 py-3">Comisión AndanDO</th>
                            <th class="px-5 py-3"></th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <tr v-for="provider in providers.data" :key="provider.id" class="hover:bg-slate-50">
                            <td class="px-5 py-4">
                                <p class="font-medium text-slate-800">{{ provider.business_name }}</p>
                                <p class="text-xs text-slate-500">{{ provider.rnc ?? 'Sin RNC' }} · {{ provider.city ?? '—' }}</p>
                            </td>
                            <td class="px-5 py-4">
                                <p class="text-slate-700">{{ provider.user?.name ?? '—' }}</p>
                                <p class="text-xs text-slate-500">{{ provider.user?.email ?? '—' }}</p>
                            </td>
                            <td class="px-5 py-4"><StatusBadge :status="provider.status" /></td>
                            <td class="px-5 py-4">
                                <div class="flex w-36 items-center rounded-lg border border-slate-200 bg-white focus-within:border-sky-500">
                                    <input
                                        v-model.number="commissionValues[provider.id]"
                                        type="number"
                                        min="0"
                                        max="100"
                                        step="0.01"
                                        class="w-full rounded-l-lg border-0 px-3 py-2 text-right text-sm outline-none"
                                    />
                                    <span class="pr-3 text-slate-400">%</span>
                                </div>
                                <p v-if="provider.latest_commission_change" class="mt-1 text-xs text-slate-400">
                                    {{ percentLabel(provider.latest_commission_change.old_rate) }}
                                    → {{ percentLabel(provider.latest_commission_change.new_rate) }}
                                    · {{ provider.latest_commission_change.changed_by?.name ?? 'Sistema' }}
                                    · {{ formatDateTime(provider.latest_commission_change.created_at) }}
                                </p>
                            </td>
                            <td class="px-5 py-4 text-right">
                                <div class="flex items-center justify-end gap-3">
                                    <Link href="/admin/afiliados?status=approved" class="text-sm text-slate-500 hover:underline">Afiliados</Link>
                                    <button
                                        class="rounded-lg bg-sky-600 px-3 py-2 text-sm font-medium text-white hover:bg-sky-700 disabled:opacity-50"
                                        :disabled="processingId === provider.id"
                                        @click="save(provider)"
                                    >
                                        {{ processingId === provider.id ? 'Guardando…' : 'Guardar' }}
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="!providers.data.length">
                            <td colspan="5" class="px-5 py-12 text-center text-slate-400">No se encontraron afiliados.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="mt-4"><Pagination :links="providers.links" /></div>
    </AdminLayout>
</template>
