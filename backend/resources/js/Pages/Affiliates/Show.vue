<script setup lang="ts">
import { ref, computed } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import { formatDateTime, documentLabel, formatBytes } from '@/lib/format';
import type { VerificationRequest } from '@/types';

const props = defineProps<{
    request: VerificationRequest;
    defaultCommissionPercent: number;
}>();

const processing = ref(false);
const showApprove = ref(false);
const showReject = ref(false);
const showSuspend = ref(false);
const showReactivate = ref(false);
const approvalCommissionPercent = ref(
    props.request.provider?.commission_rate === null
    || props.request.provider?.commission_rate === undefined
        ? props.defaultCommissionPercent
        : Number(props.request.provider.commission_rate) * 100,
);
const currentCommissionPercent = ref(approvalCommissionPercent.value);
const commissionProcessing = ref(false);

const isPending = computed(() => props.request.status === 'pending');
const providerId = computed(() => props.request.provider?.id);
const providerStatus = computed(() => props.request.provider?.status);

function approve() {
    processing.value = true;
    router.post(
        `/admin/afiliados/${props.request.id}/aprobar`,
        { commission_percent: approvalCommissionPercent.value },
        {
            onSuccess: () => { showApprove.value = false; },
            onFinish: () => { processing.value = false; },
        },
    );
}

function reject(reason: string) {
    processing.value = true;
    router.post(
        `/admin/afiliados/${props.request.id}/rechazar`,
        { reason },
        { onFinish: () => { processing.value = false; showReject.value = false; } },
    );
}

function suspend() {
    processing.value = true;
    router.post(
        `/admin/proveedores/${providerId.value}/suspender`,
        {},
        { onFinish: () => { processing.value = false; showSuspend.value = false; } },
    );
}

function reactivate() {
    processing.value = true;
    router.post(
        `/admin/proveedores/${providerId.value}/reactivar`,
        {},
        { onFinish: () => { processing.value = false; showReactivate.value = false; } },
    );
}

function updateCommission() {
    const value = Number(currentCommissionPercent.value);

    if (!Number.isFinite(value) || value < 0 || value > 100 || !providerId.value) {
        window.alert('La comisión debe estar entre 0% y 100%.');
        return;
    }

    commissionProcessing.value = true;
    router.patch(
        `/admin/comisiones/${providerId.value}`,
        { commission_percent: value },
        { onFinish: () => { commissionProcessing.value = false; } },
    );
}

function isImage(mime?: string | null): boolean {
    return !!mime && mime.startsWith('image/');
}
</script>

<template>
    <Head title="Solicitud de afiliado" />
    <AdminLayout>
        <template #title>Solicitud de afiliado</template>

        <Link href="/admin/afiliados" class="mb-4 inline-block text-sm text-sky-600 hover:underline">
            ← Volver a afiliados
        </Link>

        <!-- Banner de suspensión -->
        <div
            v-if="providerStatus === 'suspended'"
            class="mb-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800"
        >
            Esta cuenta está <strong>suspendida</strong>. El afiliado no puede iniciar sesión
            en la app ni crear experiencias hasta que se reactive.
        </div>

        <div class="grid gap-6 lg:grid-cols-3">
            <!-- Columna principal -->
            <div class="space-y-6 lg:col-span-2">
                <!-- Datos del negocio -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-4 flex items-start justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900">
                                {{ request.provider?.business_name }}
                            </h2>
                            <p class="text-sm text-slate-500">
                                {{ request.provider?.business_type?.name }}
                            </p>
                        </div>
                        <StatusBadge :status="providerStatus ?? request.status" />
                    </div>

                    <dl class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <dt class="text-slate-500">RNC</dt>
                            <dd class="font-medium text-slate-800">{{ request.provider?.rnc ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Ubicación</dt>
                            <dd class="font-medium text-slate-800">
                                {{ request.provider?.city }}, {{ request.provider?.province }}
                            </dd>
                        </div>
                        <div class="col-span-2">
                            <dt class="text-slate-500">Dirección</dt>
                            <dd class="font-medium text-slate-800">{{ request.provider?.address ?? '—' }}</dd>
                        </div>
                    </dl>
                </section>

                <!-- Documentos -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">
                        Documentos ({{ request.documents?.length ?? 0 }})
                    </h3>

                    <div v-if="request.documents?.length" class="space-y-3">
                        <div
                            v-for="doc in request.documents"
                            :key="doc.id"
                            class="flex items-center justify-between rounded-lg border border-slate-200 p-3"
                        >
                            <div class="flex items-center gap-3">
                                <div
                                    class="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-100 text-xs font-medium text-slate-500"
                                >
                                    {{ isImage(doc.mime_type) ? 'IMG' : 'DOC' }}
                                </div>
                                <div>
                                    <p class="text-sm font-medium text-slate-800">
                                        {{ documentLabel(doc.type) }}
                                    </p>
                                    <p class="text-xs text-slate-500">
                                        {{ doc.original_name }} · {{ formatBytes(doc.size_bytes) }}
                                    </p>
                                </div>
                            </div>
                            <a
                                :href="`/admin/documentos/${doc.id}`"
                                target="_blank"
                                rel="noopener"
                                class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-sky-600 hover:bg-sky-50"
                            >
                                Ver
                            </a>
                        </div>
                    </div>
                    <p v-else class="text-sm text-slate-400">
                        Esta solicitud no tiene documentos cargados.
                    </p>
                </section>

                <!-- Términos -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Aceptación legal</h3>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <p class="text-slate-500">Términos</p>
                            <p class="font-medium" :class="request.terms_accepted ? 'text-emerald-600' : 'text-rose-600'">
                                {{ request.terms_accepted ? 'Aceptados' : 'No aceptados' }}
                                <span v-if="request.terms_version" class="text-slate-400">
                                    (v{{ request.terms_version }})
                                </span>
                            </p>
                        </div>
                        <div>
                            <p class="text-slate-500">Privacidad</p>
                            <p class="font-medium" :class="request.privacy_accepted ? 'text-emerald-600' : 'text-rose-600'">
                                {{ request.privacy_accepted ? 'Aceptada' : 'No aceptada' }}
                                <span v-if="request.privacy_version" class="text-slate-400">
                                    (v{{ request.privacy_version }})
                                </span>
                            </p>
                        </div>
                    </div>
                </section>
            </div>

            <!-- Columna lateral -->
            <div class="space-y-6">
                <!-- Contacto -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Contacto</h3>
                    <dl class="space-y-2 text-sm">
                        <div>
                            <dt class="text-slate-500">Nombre</dt>
                            <dd class="font-medium text-slate-800">{{ request.provider?.user?.name }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Correo</dt>
                            <dd class="font-medium text-slate-800">{{ request.provider?.user?.email }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Teléfono</dt>
                            <dd class="font-medium text-slate-800">
                                {{ request.provider?.user?.phone ?? '—' }}
                            </dd>
                        </div>
                    </dl>
                </section>

                <!-- AndanDO Provider Commissions Module -->
                <section
                    v-if="providerStatus === 'approved' || providerStatus === 'suspended'"
                    class="rounded-xl bg-white p-6 shadow-sm"
                >
                    <h3 class="mb-2 font-semibold text-slate-800">Comisión AndanDO</h3>
                    <p class="mb-3 text-xs text-slate-500">
                        Se aplicará únicamente a reservas y transacciones nuevas.
                    </p>
                    <div class="flex items-center gap-2">
                        <div class="flex flex-1 items-center rounded-lg border border-slate-200 focus-within:border-sky-500">
                            <input
                                v-model.number="currentCommissionPercent"
                                type="number"
                                min="0"
                                max="100"
                                step="0.01"
                                class="w-full rounded-l-lg border-0 px-3 py-2 text-right text-sm outline-none"
                            />
                            <span class="pr-3 text-slate-400">%</span>
                        </div>
                        <button
                            class="rounded-lg bg-sky-600 px-3 py-2 text-sm font-medium text-white hover:bg-sky-700 disabled:opacity-50"
                            :disabled="commissionProcessing"
                            @click="updateCommission"
                        >
                            {{ commissionProcessing ? 'Guardando…' : 'Guardar' }}
                        </button>
                    </div>
                </section>

                <!-- Estado de revisión -->
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Revisión</h3>
                    <dl class="space-y-2 text-sm">
                        <div>
                            <dt class="text-slate-500">Enviada</dt>
                            <dd class="font-medium text-slate-800">{{ formatDateTime(request.submitted_at) }}</dd>
                        </div>
                        <div v-if="request.reviewed_at">
                            <dt class="text-slate-500">Revisada</dt>
                            <dd class="font-medium text-slate-800">{{ formatDateTime(request.reviewed_at) }}</dd>
                        </div>
                        <div v-if="request.reviewer">
                            <dt class="text-slate-500">Revisada por</dt>
                            <dd class="font-medium text-slate-800">{{ request.reviewer.name }}</dd>
                        </div>
                        <div v-if="request.rejection_reason">
                            <dt class="text-slate-500">Motivo de rechazo</dt>
                            <dd class="font-medium text-rose-600">{{ request.rejection_reason }}</dd>
                        </div>
                    </dl>
                </section>

                <!-- Revisión inicial (solo pendientes) -->
                <section v-if="isPending" class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Revisión</h3>
                    <div class="space-y-2">
                        <button
                            class="w-full rounded-lg bg-emerald-600 py-2.5 text-sm font-medium text-white hover:bg-emerald-700"
                            @click="showApprove = true"
                        >
                            Aprobar afiliado
                        </button>
                        <button
                            class="w-full rounded-lg border border-rose-200 py-2.5 text-sm font-medium text-rose-600 hover:bg-rose-50"
                            @click="showReject = true"
                        >
                            Rechazar
                        </button>
                    </div>
                </section>

                <!-- Gestión de cuenta (según estado del proveedor) -->
                <section
                    v-if="providerStatus === 'approved'"
                    class="rounded-xl bg-white p-6 shadow-sm"
                >
                    <h3 class="mb-3 font-semibold text-slate-800">Gestión de cuenta</h3>
                    <button
                        class="w-full rounded-lg bg-amber-600 py-2.5 text-sm font-medium text-white hover:bg-amber-700"
                        @click="showSuspend = true"
                    >
                        Suspender cuenta
                    </button>
                    <p class="mt-3 text-xs text-slate-400">
                        Cierra su sesión en la app y le impide crear experiencias o volver a
                        iniciar sesión hasta reactivarla.
                    </p>
                </section>

                <section
                    v-else-if="providerStatus === 'suspended'"
                    class="rounded-xl bg-white p-6 shadow-sm"
                >
                    <h3 class="mb-3 font-semibold text-slate-800">Gestión de cuenta</h3>
                    <button
                        class="w-full rounded-lg bg-emerald-600 py-2.5 text-sm font-medium text-white hover:bg-emerald-700"
                        @click="showReactivate = true"
                    >
                        Reactivar cuenta
                    </button>
                    <p class="mt-3 text-xs text-slate-400">
                        Restaura el acceso del afiliado a la app y a la creación de experiencias.
                    </p>
                </section>

                <section
                    v-else-if="providerStatus === 'rejected'"
                    class="rounded-xl bg-slate-50 p-6 text-center text-sm text-slate-500"
                >
                    Esta solicitud fue rechazada.
                </section>
            </div>
        </div>

        <!-- Modales -->
        <!-- AndanDO Provider Commissions Module: aprobación con comisión -->
        <div v-if="showApprove" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4">
            <div class="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
                <h3 class="text-lg font-semibold text-slate-900">Aprobar afiliado</h3>
                <p class="mt-2 text-sm text-slate-600">
                    Asigna la comisión de AndanDO antes de habilitar al afiliado.
                </p>
                <label class="mt-5 block text-sm font-medium text-slate-700">
                    Comisión AndanDO
                    <div class="mt-1 flex items-center rounded-lg border border-slate-300 focus-within:border-sky-500">
                        <input
                            v-model.number="approvalCommissionPercent"
                            type="number"
                            min="0"
                            max="100"
                            step="0.01"
                            required
                            class="w-full rounded-l-lg border-0 px-3 py-2.5 text-right outline-none"
                        />
                        <span class="pr-3 text-slate-400">%</span>
                    </div>
                </label>
                <p class="mt-2 text-xs text-slate-500">
                    El afiliado recibirá {{ (100 - Number(approvalCommissionPercent || 0)).toFixed(2) }}%.
                </p>
                <div class="mt-6 flex justify-end gap-2">
                    <button
                        class="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50"
                        :disabled="processing"
                        @click="showApprove = false"
                    >
                        Cancelar
                    </button>
                    <button
                        class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50"
                        :disabled="processing || !Number.isFinite(Number(approvalCommissionPercent)) || approvalCommissionPercent < 0 || approvalCommissionPercent > 100"
                        @click="approve"
                    >
                        {{ processing ? 'Aprobando…' : 'Aprobar afiliado' }}
                    </button>
                </div>
            </div>
        </div>
        <ConfirmModal
            :show="showReject"
            title="Rechazar solicitud"
            message="Indica el motivo del rechazo. El afiliado podrá verlo."
            confirm-text="Rechazar"
            confirm-color="danger"
            require-reason
            :processing="processing"
            @confirm="reject"
            @cancel="showReject = false"
        />
        <ConfirmModal
            :show="showSuspend"
            title="Suspender cuenta"
            message="Se cerrará su sesión en la app de inmediato y no podrá operar ni volver a entrar hasta reactivarla. ¿Confirmas?"
            confirm-text="Suspender"
            confirm-color="danger"
            :processing="processing"
            @confirm="suspend"
            @cancel="showSuspend = false"
        />
        <ConfirmModal
            :show="showReactivate"
            title="Reactivar cuenta"
            message="El afiliado recuperará el acceso a la app y a la creación de experiencias. ¿Confirmas?"
            confirm-text="Reactivar"
            confirm-color="success"
            :processing="processing"
            @confirm="reactivate"
            @cancel="showReactivate = false"
        />
    </AdminLayout>
</template>
