<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import { formatDateTime, documentLabel, formatBytes } from '@/lib/format';
import type { VerificationRequest } from '@/types';

const props = defineProps<{
    request: VerificationRequest;
}>();

const processing = ref(false);
const showApprove = ref(false);
const showReject = ref(false);

const isPending = props.request.status === 'pending';

function approve() {
    processing.value = true;
    router.post(
        `/admin/afiliados/${props.request.id}/aprobar`,
        {},
        {
            onFinish: () => {
                processing.value = false;
                showApprove.value = false;
            },
        },
    );
}

function reject(reason: string) {
    processing.value = true;
    router.post(
        `/admin/afiliados/${props.request.id}/rechazar`,
        { reason },
        {
            onFinish: () => {
                processing.value = false;
                showReject.value = false;
            },
        },
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
                        <StatusBadge :status="request.status" />
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

                <!-- Acciones -->
                <section v-if="isPending" class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Acciones</h3>
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
                <section v-else class="rounded-xl bg-slate-50 p-6 text-center text-sm text-slate-500">
                    Esta solicitud ya fue revisada.
                </section>
            </div>
        </div>

        <!-- Modales -->
        <ConfirmModal
            :show="showApprove"
            title="Aprobar afiliado"
            message="El proveedor podrá publicar experiencias. ¿Confirmas?"
            confirm-text="Aprobar"
            confirm-color="success"
            :processing="processing"
            @confirm="approve"
            @cancel="showApprove = false"
        />
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
    </AdminLayout>
</template>
