<script setup lang="ts">
// AndanDO Admin Payments UI
import { Head, Link } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime, formatMoney } from '@/lib/format';

const props = defineProps<{
    transaction: Record<string, any>;
    refundedTotal: number;
}>();

function prettyJson(value: unknown): string {
    if (!value) return 'Sin información registrada.';
    return JSON.stringify(value, null, 2);
}
</script>

<template>
    <Head :title="`Transacción #${transaction.id}`" />
    <AdminLayout>
        <template #title>Detalle de transacción</template>

        <Link href="/admin/pagos" class="mb-4 inline-block text-sm text-sky-600 hover:underline">← Volver a transacciones</Link>

        <div v-if="transaction.status === 'pending_verification'" class="mb-5 rounded-xl border border-violet-200 bg-violet-50 p-4 text-sm text-violet-800">
            El resultado del cobro no pudo confirmarse. Verifica la operación en Azul antes de realizar cualquier acción financiera.
        </div>

        <div class="grid gap-6 xl:grid-cols-3">
            <div class="space-y-6 xl:col-span-2">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-5 flex flex-wrap items-start justify-between gap-3">
                        <div>
                            <p class="text-xs uppercase tracking-wide text-slate-400">Transacción</p>
                            <h2 class="text-xl font-semibold text-slate-900">#{{ transaction.id }}</h2>
                        </div>
                        <StatusBadge :status="transaction.status" />
                    </div>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
                        <div><dt class="text-slate-500">Monto cobrado</dt><dd class="font-semibold text-slate-900">{{ formatMoney(transaction.amount, transaction.currency) }}</dd></div>
                        <div><dt class="text-slate-500">Monto devuelto</dt><dd class="font-semibold text-indigo-600">{{ formatMoney(refundedTotal, transaction.currency) }}</dd></div>
                        <div><dt class="text-slate-500">ITBIS</dt><dd class="font-medium text-slate-800">{{ formatMoney(transaction.itbis_amount ?? 0, transaction.currency) }}</dd></div>
                        <div><dt class="text-slate-500">Comisión AndanDO</dt><dd class="font-medium text-slate-800">{{ formatMoney(transaction.andando_commission_amount ?? 0, transaction.currency) }}</dd></div>
                        <div><dt class="text-slate-500">Monto afiliado</dt><dd class="font-medium text-slate-800">{{ formatMoney(transaction.provider_amount ?? 0, transaction.currency) }}</dd></div>
                        <div><dt class="text-slate-500">Procesada</dt><dd class="font-medium text-slate-800">{{ formatDateTime(transaction.processed_at) }}</dd></div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Reserva asociada</h3>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2">
                        <div><dt class="text-slate-500">Código</dt><dd class="font-medium text-slate-800">{{ transaction.booking?.booking_code ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Experiencia</dt><dd class="font-medium text-slate-800">{{ transaction.booking?.experience?.title ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Fecha</dt><dd class="font-medium text-slate-800">{{ formatDateTime(transaction.booking?.booking_date) }}</dd></div>
                        <div><dt class="text-slate-500">Estado</dt><dd class="font-medium text-slate-800">{{ transaction.booking?.status ?? '—' }}</dd></div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-4 flex items-center justify-between">
                        <h3 class="font-semibold text-slate-800">Devoluciones</h3>
                        <Link href="/admin/devoluciones" class="text-sm text-sky-600 hover:underline">Ver todas</Link>
                    </div>
                    <div v-if="transaction.refunds?.length" class="divide-y divide-slate-100">
                        <div v-for="refund in transaction.refunds" :key="refund.id" class="flex flex-wrap items-center justify-between gap-3 py-4">
                            <div>
                                <p class="font-medium text-slate-800">Devolución #{{ refund.id }}</p>
                                <p class="text-xs text-slate-500">{{ formatDateTime(refund.processed_at ?? refund.created_at) }} · {{ refund.reason ?? 'Sin motivo' }}</p>
                            </div>
                            <div class="flex items-center gap-4">
                                <span class="font-medium text-slate-800">{{ formatMoney(refund.amount, refund.currency) }}</span>
                                <StatusBadge :status="refund.status" />
                                <Link :href="`/admin/devoluciones/${refund.id}`" class="text-sm font-medium text-sky-600 hover:underline">Revisar</Link>
                            </div>
                        </div>
                    </div>
                    <p v-else class="py-6 text-center text-sm text-slate-400">Esta transacción no tiene devoluciones.</p>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Trazabilidad de pasarela</h3>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2">
                        <div><dt class="text-slate-500">Azul Order ID</dt><dd class="break-all font-mono text-xs text-slate-800">{{ transaction.gateway_order_id ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">RRN</dt><dd class="break-all font-mono text-xs text-slate-800">{{ transaction.gateway_rrn ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Autorización</dt><dd class="break-all font-mono text-xs text-slate-800">{{ transaction.gateway_authorization_code ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Código / ISO</dt><dd class="font-medium text-slate-800">{{ transaction.gateway_response_code ?? '—' }} / {{ transaction.gateway_iso_code ?? '—' }}</dd></div>
                        <div class="sm:col-span-2"><dt class="text-slate-500">Mensaje</dt><dd class="font-medium text-slate-800">{{ transaction.gateway_response_message ?? transaction.gateway_error_description ?? transaction.failure_reason ?? '—' }}</dd></div>
                    </dl>
                    <details class="mt-5 rounded-lg border border-slate-200 p-4">
                        <summary class="cursor-pointer text-sm font-medium text-slate-700">Solicitud sanitizada</summary>
                        <pre class="mt-3 max-h-80 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-slate-950 p-4 text-xs text-slate-200">{{ prettyJson(transaction.raw_request) }}</pre>
                    </details>
                    <details class="mt-3 rounded-lg border border-slate-200 p-4">
                        <summary class="cursor-pointer text-sm font-medium text-slate-700">Respuesta sanitizada</summary>
                        <pre class="mt-3 max-h-80 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-slate-950 p-4 text-xs text-slate-200">{{ prettyJson(transaction.raw_response) }}</pre>
                    </details>
                </section>
            </div>

            <div class="space-y-6">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Cliente</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Nombre</dt><dd class="font-medium text-slate-800">{{ transaction.user?.name ?? transaction.booking?.customer_name ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Correo</dt><dd class="break-all font-medium text-slate-800">{{ transaction.user?.email ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Teléfono</dt><dd class="font-medium text-slate-800">{{ transaction.user?.phone ?? '—' }}</dd></div>
                    </dl>
                </section>
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Afiliado</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Negocio</dt><dd class="font-medium text-slate-800">{{ transaction.provider?.business_name ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Contacto</dt><dd class="font-medium text-slate-800">{{ transaction.provider?.user?.name ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Correo</dt><dd class="break-all font-medium text-slate-800">{{ transaction.provider?.user?.email ?? '—' }}</dd></div>
                    </dl>
                </section>
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Procesamiento</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Pasarela</dt><dd class="font-medium text-slate-800">{{ transaction.gateway }}</dd></div>
                        <div><dt class="text-slate-500">Ambiente</dt><dd class="font-medium text-slate-800">{{ transaction.environment }}</dd></div>
                        <div><dt class="text-slate-500">Programada</dt><dd class="font-medium text-slate-800">{{ formatDateTime(transaction.charge_scheduled_at) }}</dd></div>
                        <div><dt class="text-slate-500">Idempotencia</dt><dd class="break-all font-mono text-xs text-slate-800">{{ transaction.idempotency_key }}</dd></div>
                    </dl>
                </section>
            </div>
        </div>
    </AdminLayout>
</template>
