<script setup lang="ts">
// AndanDO Admin Payments UI
import { reactive, ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import Pagination from '@/Components/Pagination.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime, formatMoney } from '@/lib/format';

interface Refund {
    id: number;
    payment_transaction_id: number;
    status: string;
    reason?: string | null;
    amount: string | number;
    currency: string;
    refund_percent?: string | number | null;
    gateway: string;
    environment: string;
    gateway_refund_id?: string | null;
    gateway_response_message?: string | null;
    gateway_error_description?: string | null;
    processed_at?: string | null;
    created_at?: string | null;
    can_retry: boolean;
    user?: { id: number; name: string; email?: string } | null;
    booking?: {
        id: number;
        booking_code: string;
        customer_name?: string | null;
        experience?: { id: number; title: string } | null;
        provider?: { id: number; business_name: string } | null;
    } | null;
}

interface PaginationLink { url: string | null; label: string; active: boolean }
interface Paginated<T> { data: T[]; links: PaginationLink[]; total: number }

const props = defineProps<{
    refunds: Paginated<Refund>;
    filters: { search: string; status: string; gateway: string; from: string; to: string };
    gateways: string[];
    counts: { all: number; failed: number; pending_verification: number; succeeded: number };
}>();

const form = reactive({ ...props.filters });
const selectedRefund = ref<Refund | null>(null);
const processing = ref(false);

function applyFilters() {
    router.get('/admin/devoluciones', { ...form }, { preserveState: true, replace: true });
}

function setStatus(status: string) {
    form.status = status;
    applyFilters();
}

function resetFilters() {
    Object.assign(form, { search: '', status: 'all', gateway: '', from: '', to: '' });
    applyFilters();
}

function retryRefund() {
    if (!selectedRefund.value) return;
    processing.value = true;
    router.post(`/admin/devoluciones/${selectedRefund.value.id}/reintentar`, {}, {
        preserveScroll: true,
        onFinish: () => {
            processing.value = false;
            selectedRefund.value = null;
        },
    });
}
</script>

<template>
    <Head title="Devoluciones" />
    <AdminLayout>
        <template #title>Pagos y devoluciones</template>

        <div class="mb-5 flex gap-1 rounded-xl bg-white p-1 shadow-sm">
            <Link href="/admin/pagos" class="flex-1 rounded-lg px-4 py-2.5 text-center text-sm font-medium text-slate-600 hover:bg-slate-100">Transacciones</Link>
            <Link href="/admin/devoluciones" class="flex-1 rounded-lg bg-sky-600 px-4 py-2.5 text-center text-sm font-medium text-white">Devoluciones</Link>
        </div>

        <div class="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
            <button class="rounded-xl bg-white p-4 text-left shadow-sm" @click="setStatus('all')">
                <p class="text-xs uppercase tracking-wide text-slate-500">Todas</p><p class="mt-1 text-2xl font-semibold text-slate-800">{{ counts.all }}</p>
            </button>
            <button class="rounded-xl bg-white p-4 text-left shadow-sm" @click="setStatus('failed')">
                <p class="text-xs uppercase tracking-wide text-slate-500">Fallidas</p><p class="mt-1 text-2xl font-semibold text-rose-600">{{ counts.failed }}</p>
            </button>
            <button class="rounded-xl bg-white p-4 text-left shadow-sm" @click="setStatus('pending_verification')">
                <p class="text-xs uppercase tracking-wide text-slate-500">Por verificar</p><p class="mt-1 text-2xl font-semibold text-violet-600">{{ counts.pending_verification }}</p>
            </button>
            <button class="rounded-xl bg-white p-4 text-left shadow-sm" @click="setStatus('succeeded')">
                <p class="text-xs uppercase tracking-wide text-slate-500">Completadas</p><p class="mt-1 text-2xl font-semibold text-emerald-600">{{ counts.succeeded }}</p>
            </button>
        </div>

        <form class="mb-5 rounded-xl bg-white p-4 shadow-sm" @submit.prevent="applyFilters">
            <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
                <input v-model="form.search" type="search" placeholder="ID, reserva, cliente, referencia..." class="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-sky-500 xl:col-span-2" />
                <select v-model="form.status" class="rounded-lg border border-slate-200 px-3 py-2 text-sm">
                    <option value="all">Todos los estados</option>
                    <option value="pending">Pendientes</option>
                    <option value="processing">Procesando</option>
                    <option value="pending_verification">Por verificar</option>
                    <option value="succeeded">Completadas</option>
                    <option value="failed">Fallidas</option>
                </select>
                <select v-model="form.gateway" class="rounded-lg border border-slate-200 px-3 py-2 text-sm">
                    <option value="">Todas las pasarelas</option>
                    <option v-for="gateway in gateways" :key="gateway" :value="gateway">{{ gateway }}</option>
                </select>
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 rounded-lg bg-sky-600 px-3 py-2 text-sm font-medium text-white hover:bg-sky-700">Filtrar</button>
                    <button type="button" class="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600" @click="resetFilters">Limpiar</button>
                </div>
            </div>
            <div class="mt-3 grid gap-3 sm:grid-cols-2 xl:w-2/5">
                <label class="text-xs text-slate-500">Desde<input v-model="form.from" type="date" class="mt-1 block w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" /></label>
                <label class="text-xs text-slate-500">Hasta<input v-model="form.to" type="date" class="mt-1 block w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" /></label>
            </div>
        </form>

        <div class="overflow-hidden rounded-xl bg-white shadow-sm">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                    <thead class="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                            <th class="px-5 py-3">Devolución</th><th class="px-5 py-3">Reserva</th><th class="px-5 py-3">Cliente</th><th class="px-5 py-3">Afiliado</th><th class="px-5 py-3 text-right">Monto</th><th class="px-5 py-3">Estado</th><th class="px-5 py-3">Fecha</th><th class="px-5 py-3"></th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <tr v-for="refund in refunds.data" :key="refund.id" class="hover:bg-slate-50">
                            <td class="px-5 py-3"><p class="font-medium text-slate-800">#{{ refund.id }}</p><p class="text-xs text-slate-400">Pago #{{ refund.payment_transaction_id }} · {{ refund.gateway }}</p></td>
                            <td class="px-5 py-3"><p class="font-medium text-slate-700">{{ refund.booking?.booking_code ?? '—' }}</p><p class="max-w-48 truncate text-xs text-slate-400">{{ refund.booking?.experience?.title ?? '—' }}</p></td>
                            <td class="px-5 py-3 text-slate-600">{{ refund.user?.name ?? refund.booking?.customer_name ?? '—' }}</td>
                            <td class="px-5 py-3 text-slate-600">{{ refund.booking?.provider?.business_name ?? '—' }}</td>
                            <td class="px-5 py-3 text-right font-medium text-slate-800">{{ formatMoney(refund.amount, refund.currency) }}</td>
                            <td class="px-5 py-3"><StatusBadge :status="refund.status" /></td>
                            <td class="whitespace-nowrap px-5 py-3 text-slate-500">{{ formatDateTime(refund.processed_at ?? refund.created_at) }}</td>
                            <td class="px-5 py-3"><div class="flex items-center justify-end gap-3"><button v-if="refund.can_retry" class="font-medium text-rose-600 hover:underline" @click="selectedRefund = refund">Reintentar</button><Link :href="`/admin/devoluciones/${refund.id}`" class="font-medium text-sky-600 hover:underline">Revisar</Link></div></td>
                        </tr>
                        <tr v-if="!refunds.data.length"><td colspan="8" class="px-5 py-12 text-center text-slate-400">No se encontraron devoluciones.</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="mt-4"><Pagination :links="refunds.links" /></div>

        <ConfirmModal
            :show="selectedRefund !== null"
            title="Reintentar devolución"
            :message="selectedRefund ? `Se volverá a solicitar a ${selectedRefund.gateway} la devolución de ${formatMoney(selectedRefund.amount, selectedRefund.currency)}. La acción quedará registrada a tu nombre.` : ''"
            confirm-text="Reintentar devolución"
            confirm-color="danger"
            :processing="processing"
            @confirm="retryRefund"
            @cancel="selectedRefund = null"
        />
    </AdminLayout>
</template>
