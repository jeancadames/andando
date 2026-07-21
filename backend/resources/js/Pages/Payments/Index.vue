<script setup lang="ts">
// AndanDO Admin Payments UI
import { reactive } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime, formatMoney } from '@/lib/format';

interface Transaction {
    id: number;
    status: string;
    type: string;
    amount: string | number;
    currency: string;
    gateway: string;
    environment: string;
    gateway_order_id?: string | null;
    gateway_rrn?: string | null;
    processed_at?: string | null;
    created_at?: string | null;
    refunded_amount?: string | number | null;
    booking?: {
        id: number;
        booking_code: string;
        customer_name?: string | null;
        experience?: { id: number; title: string } | null;
    } | null;
    user?: { id: number; name: string; email?: string } | null;
    provider?: { id: number; business_name: string } | null;
}

interface PaginationLink {
    url: string | null;
    label: string;
    active: boolean;
}

interface Paginated<T> {
    data: T[];
    links: PaginationLink[];
    total: number;
    from?: number | null;
    to?: number | null;
}

const props = defineProps<{
    transactions: Paginated<Transaction>;
    filters: { search: string; status: string; gateway: string; from: string; to: string };
    gateways: string[];
    summary: {
        charged_total: number;
        refunded_total: number;
        pending_verification: number;
        failed_refunds: number;
    };
}>();

const form = reactive({ ...props.filters });

function applyFilters() {
    router.get('/admin/pagos', { ...form }, { preserveState: true, replace: true });
}

function resetFilters() {
    Object.assign(form, { search: '', status: 'all', gateway: '', from: '', to: '' });
    applyFilters();
}
</script>

<template>
    <Head title="Pagos" />
    <AdminLayout>
        <template #title>Pagos y devoluciones</template>

        <div class="mb-5 flex gap-1 rounded-xl bg-white p-1 shadow-sm">
            <Link href="/admin/pagos" class="flex-1 rounded-lg bg-sky-600 px-4 py-2.5 text-center text-sm font-medium text-white">
                Transacciones
            </Link>
            <Link href="/admin/devoluciones" class="flex-1 rounded-lg px-4 py-2.5 text-center text-sm font-medium text-slate-600 hover:bg-slate-100">
                Devoluciones
            </Link>
        </div>

        <div class="mb-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <div class="rounded-xl bg-white p-5 shadow-sm">
                <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Total cobrado</p>
                <p class="mt-2 text-2xl font-semibold text-emerald-600">{{ formatMoney(summary.charged_total) }}</p>
            </div>
            <div class="rounded-xl bg-white p-5 shadow-sm">
                <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Total devuelto</p>
                <p class="mt-2 text-2xl font-semibold text-indigo-600">{{ formatMoney(summary.refunded_total) }}</p>
            </div>
            <div class="rounded-xl bg-white p-5 shadow-sm">
                <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Cobros por verificar</p>
                <p class="mt-2 text-2xl font-semibold text-violet-600">{{ summary.pending_verification }}</p>
            </div>
            <Link href="/admin/devoluciones?status=failed" class="rounded-xl bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Devoluciones fallidas</p>
                <p class="mt-2 text-2xl font-semibold text-rose-600">{{ summary.failed_refunds }}</p>
            </Link>
        </div>

        <form class="mb-5 rounded-xl bg-white p-4 shadow-sm" @submit.prevent="applyFilters">
            <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
                <input
                    v-model="form.search"
                    type="search"
                    placeholder="ID, reserva, cliente, afiliado, RRN..."
                    class="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-sky-500 xl:col-span-2"
                />
                <select v-model="form.status" class="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-sky-500">
                    <option value="all">Todos los estados</option>
                    <option value="scheduled">Programados</option>
                    <option value="processing">Procesando</option>
                    <option value="pending_verification">Por verificar</option>
                    <option value="paid">Pagados</option>
                    <option value="failed">Fallidos</option>
                    <option value="cancelled">Cancelados</option>
                    <option value="refunded">Reembolsados</option>
                    <option value="partially_refunded">Reembolso parcial</option>
                </select>
                <select v-model="form.gateway" class="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-sky-500">
                    <option value="">Todas las pasarelas</option>
                    <option v-for="gateway in gateways" :key="gateway" :value="gateway">{{ gateway }}</option>
                </select>
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 rounded-lg bg-sky-600 px-3 py-2 text-sm font-medium text-white hover:bg-sky-700">Filtrar</button>
                    <button type="button" class="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50" @click="resetFilters">Limpiar</button>
                </div>
            </div>
            <div class="mt-3 grid gap-3 sm:grid-cols-2 xl:w-2/5">
                <label class="text-xs text-slate-500">
                    Desde
                    <input v-model="form.from" type="date" class="mt-1 block w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label class="text-xs text-slate-500">
                    Hasta
                    <input v-model="form.to" type="date" class="mt-1 block w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" />
                </label>
            </div>
        </form>

        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                    <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                            <th class="px-5 py-3">Transacción</th>
                            <th class="px-5 py-3">Reserva</th>
                            <th class="px-5 py-3">Cliente</th>
                            <th class="px-5 py-3">Afiliado</th>
                            <th class="px-5 py-3 text-right">Monto</th>
                            <th class="px-5 py-3 text-right">Devuelto</th>
                            <th class="px-5 py-3">Estado</th>
                            <th class="px-5 py-3">Fecha</th>
                            <th class="px-5 py-3"></th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <tr v-for="transaction in transactions.data" :key="transaction.id" class="hover:bg-slate-50">
                            <td class="px-5 py-3">
                                <p class="font-medium text-slate-800">#{{ transaction.id }}</p>
                                <p class="text-xs text-slate-400">{{ transaction.gateway }} · {{ transaction.environment }}</p>
                            </td>
                            <td class="px-5 py-3">
                                <p class="font-medium text-slate-700">{{ transaction.booking?.booking_code ?? '—' }}</p>
                                <p class="max-w-48 truncate text-xs text-slate-400">{{ transaction.booking?.experience?.title ?? '—' }}</p>
                            </td>
                            <td class="px-5 py-3 text-slate-600">{{ transaction.user?.name ?? transaction.booking?.customer_name ?? '—' }}</td>
                            <td class="px-5 py-3 text-slate-600">{{ transaction.provider?.business_name ?? '—' }}</td>
                            <td class="px-5 py-3 text-right font-medium text-slate-800">{{ formatMoney(transaction.amount, transaction.currency) }}</td>
                            <td class="px-5 py-3 text-right text-indigo-600">{{ formatMoney(transaction.refunded_amount ?? 0, transaction.currency) }}</td>
                            <td class="px-5 py-3"><StatusBadge :status="transaction.status" /></td>
                            <td class="whitespace-nowrap px-5 py-3 text-slate-500">{{ formatDateTime(transaction.processed_at ?? transaction.created_at) }}</td>
                            <td class="px-5 py-3 text-right">
                                <Link :href="`/admin/pagos/${transaction.id}`" class="font-medium text-sky-600 hover:underline">Ver</Link>
                            </td>
                        </tr>
                        <tr v-if="!transactions.data.length">
                            <td colspan="9" class="px-5 py-12 text-center text-slate-400">No se encontraron transacciones.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="mt-4"><Pagination :links="transactions.links" /></div>
    </AdminLayout>
</template>
