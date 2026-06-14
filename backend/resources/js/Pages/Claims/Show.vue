<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import { formatDateTime, formatMoney } from '@/lib/format';
import type { Claim } from '@/types';

const props = defineProps<{
    claim: Claim;
}>();

const processing = ref(false);
const showResolve = ref(false);
const showReject = ref(false);

const isOpen = ['pending', 'provider_replied'].includes(props.claim.status);

function resolve() {
    processing.value = true;
    router.post(
        `/admin/reclamos/${props.claim.id}/resolver`,
        {},
        { onFinish: () => { processing.value = false; showResolve.value = false; } },
    );
}

function reject() {
    processing.value = true;
    router.post(
        `/admin/reclamos/${props.claim.id}/rechazar`,
        {},
        { onFinish: () => { processing.value = false; showReject.value = false; } },
    );
}
</script>

<template>
    <Head title="Reclamo" />
    <AdminLayout>
        <template #title>Detalle del reclamo</template>

        <Link href="/admin/reclamos" class="mb-4 inline-block text-sm text-sky-600 hover:underline">
            ← Volver a reclamos
        </Link>

        <div class="grid gap-6 lg:grid-cols-3">
            <div class="space-y-6 lg:col-span-2">
                <!-- Reclamo -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-4 flex items-start justify-between">
                        <h2 class="text-lg font-semibold text-slate-900">{{ claim.reason }}</h2>
                        <StatusBadge :status="claim.status" />
                    </div>
                    <p class="whitespace-pre-line text-sm text-slate-700">{{ claim.description }}</p>
                    <p class="mt-4 text-xs text-slate-400">
                        Reportado el {{ formatDateTime(claim.created_at) }}
                    </p>
                </section>

                <!-- Respuesta del afiliado -->
                <section v-if="claim.provider_response" class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-2 font-semibold text-slate-800">Respuesta del afiliado</h3>
                    <p class="whitespace-pre-line text-sm text-slate-700">{{ claim.provider_response }}</p>
                    <p class="mt-3 text-xs text-slate-400">
                        {{ formatDateTime(claim.provider_replied_at) }}
                    </p>
                </section>

                <!-- Reserva -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Reserva asociada</h3>
                    <dl class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <dt class="text-slate-500">Código</dt>
                            <dd class="font-medium text-slate-800">{{ claim.booking?.booking_code ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Experiencia</dt>
                            <dd class="font-medium text-slate-800">
                                {{ claim.booking?.experience?.title ?? '—' }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Fecha de la experiencia</dt>
                            <dd class="font-medium text-slate-800">
                                {{ formatDateTime(claim.booking?.booking_date) }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Personas</dt>
                            <dd class="font-medium text-slate-800">{{ claim.booking?.guests_count ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Total</dt>
                            <dd class="font-medium text-slate-800">
                                {{ claim.booking ? formatMoney(claim.booking.total_amount) : '—' }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Estado de la reserva</dt>
                            <dd class="font-medium text-slate-800">{{ claim.booking?.status ?? '—' }}</dd>
                        </div>
                    </dl>
                </section>
            </div>

            <!-- Lateral -->
            <div class="space-y-6">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Cliente</h3>
                    <dl class="space-y-2 text-sm">
                        <div>
                            <dt class="text-slate-500">Nombre</dt>
                            <dd class="font-medium text-slate-800">{{ claim.user?.name }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Correo</dt>
                            <dd class="font-medium text-slate-800">{{ claim.user?.email }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Teléfono</dt>
                            <dd class="font-medium text-slate-800">{{ claim.user?.phone ?? '—' }}</dd>
                        </div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Afiliado</h3>
                    <dl class="space-y-2 text-sm">
                        <div>
                            <dt class="text-slate-500">Negocio</dt>
                            <dd class="font-medium text-slate-800">{{ claim.provider?.business_name }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Contacto</dt>
                            <dd class="font-medium text-slate-800">{{ claim.provider?.user?.name ?? '—' }}</dd>
                        </div>
                    </dl>
                </section>

                <section v-if="isOpen" class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Acciones</h3>
                    <div class="space-y-2">
                        <button
                            class="w-full rounded-lg bg-emerald-600 py-2.5 text-sm font-medium text-white hover:bg-emerald-700"
                            @click="showResolve = true"
                        >
                            Marcar como resuelto
                        </button>
                        <button
                            class="w-full rounded-lg border border-rose-200 py-2.5 text-sm font-medium text-rose-600 hover:bg-rose-50"
                            @click="showReject = true"
                        >
                            Rechazar reclamo
                        </button>
                    </div>
                </section>
                <section v-else class="rounded-xl bg-slate-50 p-6 text-center text-sm text-slate-500">
                    Este reclamo ya fue cerrado.
                    <span v-if="claim.resolved_at" class="block text-xs">
                        {{ formatDateTime(claim.resolved_at) }}
                    </span>
                </section>
            </div>
        </div>

        <ConfirmModal
            :show="showResolve"
            title="Resolver reclamo"
            message="¿Confirmas que este reclamo queda resuelto?"
            confirm-text="Resolver"
            confirm-color="success"
            :processing="processing"
            @confirm="resolve"
            @cancel="showResolve = false"
        />
        <ConfirmModal
            :show="showReject"
            title="Rechazar reclamo"
            message="¿Confirmas que este reclamo se rechaza?"
            confirm-text="Rechazar"
            confirm-color="danger"
            :processing="processing"
            @confirm="reject"
            @cancel="showReject = false"
        />
    </AdminLayout>
</template>
