<script setup lang="ts">
// AndanDO Admin Payments UI
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime, formatMoney } from '@/lib/format';

const props = defineProps<{ refund: Record<string, any> }>();
const confirmRetry = ref(false);
const processing = ref(false);

const reasonLabels: Record<string, string> = {
    customer_policy: 'Política de cancelación del cliente',
    provider_cancelled: 'Cancelación del afiliado',
    weather: 'Condiciones climáticas',
    force_majeure: 'Fuerza mayor',
    admin: 'Decisión administrativa',
    claim: 'Reclamo aprobado',
};

function reasonLabel(value?: string | null): string {
    if (!value) return 'Sin motivo registrado';
    return reasonLabels[value] ?? value;
}

function prettyJson(value: unknown): string {
    if (!value) return 'Sin información registrada.';
    return JSON.stringify(value, null, 2);
}

function retryRefund() {
    processing.value = true;
    router.post(`/admin/devoluciones/${props.refund.id}/reintentar`, {}, {
        preserveScroll: true,
        onFinish: () => {
            processing.value = false;
            confirmRetry.value = false;
        },
    });
}
</script>

<template>
    <Head :title="`Devolución #${refund.id}`" />
    <AdminLayout>
        <template #title>Detalle de devolución</template>

        <Link href="/admin/devoluciones" class="mb-4 inline-block text-sm text-sky-600 hover:underline">← Volver a devoluciones</Link>

        <div v-if="refund.status === 'pending_verification'" class="mb-5 rounded-xl border border-violet-200 bg-violet-50 p-4 text-sm text-violet-800">
            El resultado del último intento es desconocido. Verifica primero la operación directamente en Azul; el reintento está bloqueado para evitar devolver el dinero dos veces.
        </div>

        <div class="grid gap-6 xl:grid-cols-3">
            <div class="space-y-6 xl:col-span-2">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-5 flex flex-wrap items-start justify-between gap-3">
                        <div><p class="text-xs uppercase tracking-wide text-slate-400">Devolución</p><h2 class="text-xl font-semibold text-slate-900">#{{ refund.id }}</h2></div>
                        <StatusBadge :status="refund.status" />
                    </div>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
                        <div><dt class="text-slate-500">Monto</dt><dd class="font-semibold text-slate-900">{{ formatMoney(refund.amount, refund.currency) }}</dd></div>
                        <div><dt class="text-slate-500">Porcentaje</dt><dd class="font-medium text-slate-800">{{ refund.refund_percent ?? '—' }}%</dd></div>
                        <div><dt class="text-slate-500">Monto retenido</dt><dd class="font-medium text-slate-800">{{ formatMoney(refund.retained_amount ?? 0, refund.currency) }}</dd></div>
                        <div class="sm:col-span-2"><dt class="text-slate-500">Motivo</dt><dd class="font-medium text-slate-800">{{ reasonLabel(refund.reason) }}</dd></div>
                        <div><dt class="text-slate-500">Procesada</dt><dd class="font-medium text-slate-800">{{ formatDateTime(refund.processed_at) }}</dd></div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Reserva y pago original</h3>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2">
                        <div><dt class="text-slate-500">Reserva</dt><dd class="font-medium text-slate-800">{{ refund.booking?.booking_code ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Experiencia</dt><dd class="font-medium text-slate-800">{{ refund.booking?.experience?.title ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Transacción</dt><dd><Link :href="`/admin/pagos/${refund.payment_transaction_id}`" class="font-medium text-sky-600 hover:underline">Pago #{{ refund.payment_transaction_id }}</Link></dd></div>
                        <div><dt class="text-slate-500">Monto original</dt><dd class="font-medium text-slate-800">{{ formatMoney(refund.transaction?.amount ?? 0, refund.transaction?.currency ?? refund.currency) }}</dd></div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Respuesta vigente de la pasarela</h3>
                    <dl class="grid gap-4 text-sm sm:grid-cols-2">
                        <div><dt class="text-slate-500">Referencia devolución</dt><dd class="break-all font-mono text-xs text-slate-800">{{ refund.gateway_refund_id ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Código / ISO</dt><dd class="font-medium text-slate-800">{{ refund.gateway_response_code ?? '—' }} / {{ refund.gateway_iso_code ?? '—' }}</dd></div>
                        <div class="sm:col-span-2"><dt class="text-slate-500">Mensaje</dt><dd class="font-medium text-slate-800">{{ refund.gateway_response_message ?? refund.gateway_error_description ?? '—' }}</dd></div>
                    </dl>
                    <details class="mt-5 rounded-lg border border-slate-200 p-4"><summary class="cursor-pointer text-sm font-medium text-slate-700">Solicitud sanitizada</summary><pre class="mt-3 max-h-80 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-slate-950 p-4 text-xs text-slate-200">{{ prettyJson(refund.raw_request) }}</pre></details>
                    <details class="mt-3 rounded-lg border border-slate-200 p-4"><summary class="cursor-pointer text-sm font-medium text-slate-700">Respuesta sanitizada</summary><pre class="mt-3 max-h-80 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-slate-950 p-4 text-xs text-slate-200">{{ prettyJson(refund.raw_response) }}</pre></details>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Historial de intentos</h3>
                    <div v-if="refund.attempts?.length" class="space-y-4">
                        <article v-for="attempt in refund.attempts" :key="attempt.id" class="rounded-xl border border-slate-200 p-4">
                            <div class="flex flex-wrap items-start justify-between gap-3">
                                <div>
                                    <p class="font-medium text-slate-800">Intento #{{ attempt.attempt_number }}</p>
                                    <p class="text-xs text-slate-500">{{ attempt.trigger === 'manual' ? 'Manual' : 'Automático' }} · {{ attempt.initiated_by?.name ?? 'Sistema' }} · {{ formatDateTime(attempt.started_at) }}</p>
                                </div>
                                <StatusBadge :status="attempt.status" />
                            </div>
                            <p v-if="attempt.gateway_response_message || attempt.gateway_error_description" class="mt-3 text-sm text-slate-600">{{ attempt.gateway_response_message ?? attempt.gateway_error_description }}</p>
                            <details v-if="attempt.raw_request || attempt.raw_response" class="mt-3"><summary class="cursor-pointer text-xs font-medium text-sky-600">Ver datos técnicos</summary><pre class="mt-2 max-h-64 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-slate-950 p-3 text-xs text-slate-200">{{ prettyJson({ request: attempt.raw_request, response: attempt.raw_response }) }}</pre></details>
                        </article>
                    </div>
                    <p v-else class="rounded-lg bg-slate-50 p-4 text-sm text-slate-500">No hay reintentos manuales. El intento original se conserva en la respuesta vigente de la pasarela.</p>
                </section>
            </div>

            <div class="space-y-6">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Cliente</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Nombre</dt><dd class="font-medium text-slate-800">{{ refund.user?.name ?? refund.booking?.customer_name ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Correo</dt><dd class="break-all font-medium text-slate-800">{{ refund.user?.email ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Teléfono</dt><dd class="font-medium text-slate-800">{{ refund.user?.phone ?? '—' }}</dd></div>
                    </dl>
                </section>
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Afiliado</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Negocio</dt><dd class="font-medium text-slate-800">{{ refund.booking?.provider?.business_name ?? '—' }}</dd></div>
                        <div><dt class="text-slate-500">Contacto</dt><dd class="font-medium text-slate-800">{{ refund.booking?.provider?.user?.name ?? '—' }}</dd></div>
                    </dl>
                </section>
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Procesamiento</h3>
                    <dl class="space-y-2 text-sm">
                        <div><dt class="text-slate-500">Pasarela</dt><dd class="font-medium text-slate-800">{{ refund.gateway }}</dd></div>
                        <div><dt class="text-slate-500">Ambiente</dt><dd class="font-medium text-slate-800">{{ refund.environment }}</dd></div>
                    </dl>
                </section>
                <section v-if="refund.can_retry" class="rounded-xl border border-rose-200 bg-rose-50 p-6">
                    <h3 class="font-semibold text-rose-800">Devolución fallida</h3>
                    <p class="mt-2 text-sm text-rose-700">Puedes reintentarla manualmente. Se reutilizará la misma referencia lógica y la acción quedará registrada a tu nombre.</p>
                    <button class="mt-4 w-full rounded-lg bg-rose-600 py-2.5 text-sm font-medium text-white hover:bg-rose-700" @click="confirmRetry = true">Reintentar devolución</button>
                </section>
                <section v-else-if="refund.status === 'failed'" class="rounded-xl bg-slate-100 p-6 text-sm text-slate-600">
                    El reintento automático está bloqueado porque no existe una respuesta definitiva, cambió el ambiente/pasarela o hay otra devolución activa.
                </section>
            </div>
        </div>

        <ConfirmModal
            :show="confirmRetry"
            title="Reintentar devolución"
            :message="`Se solicitará nuevamente la devolución de ${formatMoney(refund.amount, refund.currency)} a ${refund.gateway}. La acción quedará registrada a tu nombre.`"
            confirm-text="Reintentar devolución"
            confirm-color="danger"
            :processing="processing"
            @confirm="retryRefund"
            @cancel="confirmRetry = false"
        />
    </AdminLayout>
</template>
