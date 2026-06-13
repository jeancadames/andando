<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import ConfirmModal from '@/Components/ConfirmModal.vue';
import { formatMoney, formatDateTime } from '@/lib/format';
import type { Experience } from '@/types';

const props = defineProps<{
    experience: Experience;
}>();

const processing = ref(false);
const showToggle = ref(false);
const showReject = ref(false);

function toggleActive() {
    processing.value = true;
    router.post(
        `/admin/experiencias/${props.experience.id}/estado`,
        {},
        { onFinish: () => { processing.value = false; showToggle.value = false; } },
    );
}

function reject() {
    processing.value = true;
    router.post(
        `/admin/experiencias/${props.experience.id}/rechazar`,
        {},
        { onFinish: () => { processing.value = false; showReject.value = false; } },
    );
}
</script>

<template>
    <Head title="Experiencia" />
    <AdminLayout>
        <template #title>Gestión de experiencia</template>

        <Link href="/admin/experiencias" class="mb-4 inline-block text-sm text-sky-600 hover:underline">
            ← Volver a experiencias
        </Link>

        <div class="grid gap-6 lg:grid-cols-3">
            <div class="space-y-6 lg:col-span-2">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <div class="mb-4 flex items-start justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900">{{ experience.title }}</h2>
                            <p class="text-sm text-slate-500">
                                {{ experience.category }} · {{ experience.location }}
                                <span v-if="experience.province">, {{ experience.province }}</span>
                            </p>
                        </div>
                        <div class="flex flex-col items-end gap-2">
                            <StatusBadge :status="experience.status" />
                            <span
                                class="inline-flex items-center gap-1.5 text-xs font-medium"
                                :class="experience.is_active ? 'text-emerald-600' : 'text-rose-600'"
                            >
                                <span
                                    class="inline-flex h-2 w-2 rounded-full"
                                    :class="experience.is_active ? 'bg-emerald-500' : 'bg-rose-500'"
                                />
                                {{ experience.is_active ? 'Activa' : 'Desactivada' }}
                            </span>
                        </div>
                    </div>

                    <p v-if="experience.description" class="whitespace-pre-line text-sm text-slate-700">
                        {{ experience.description }}
                    </p>

                    <dl class="mt-5 grid grid-cols-2 gap-4 text-sm sm:grid-cols-3">
                        <div>
                            <dt class="text-slate-500">Precio</dt>
                            <dd class="font-medium text-slate-800">
                                {{ formatMoney(experience.price, experience.currency ?? 'DOP') }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Capacidad</dt>
                            <dd class="font-medium text-slate-800">{{ experience.capacity }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Publicada</dt>
                            <dd class="font-medium text-slate-800">
                                {{ formatDateTime(experience.published_at) }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Reservas</dt>
                            <dd class="font-medium text-slate-800">{{ experience.bookings_count ?? 0 }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Reseñas</dt>
                            <dd class="font-medium text-slate-800">{{ experience.reviews_count ?? 0 }}</dd>
                        </div>
                    </dl>
                </section>

                <!-- Fotos -->
                <section v-if="experience.photos?.length" class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-4 font-semibold text-slate-800">Fotos</h3>
                    <div class="grid grid-cols-3 gap-3 sm:grid-cols-4">
                        <div
                            v-for="photo in experience.photos"
                            :key="photo.id"
                            class="relative aspect-square overflow-hidden rounded-lg bg-slate-100"
                        >
                            <img
                                :src="`/api/public-files/${photo.path}`"
                                :alt="experience.title"
                                class="h-full w-full object-cover"
                            />
                            <span
                                v-if="photo.is_cover"
                                class="absolute left-1 top-1 rounded bg-sky-600 px-1.5 py-0.5 text-[10px] text-white"
                            >
                                Portada
                            </span>
                        </div>
                    </div>
                </section>
            </div>

            <!-- Lateral -->
            <div class="space-y-6">
                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Afiliado</h3>
                    <dl class="space-y-2 text-sm">
                        <div>
                            <dt class="text-slate-500">Negocio</dt>
                            <dd class="font-medium text-slate-800">{{ experience.provider?.business_name }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Contacto</dt>
                            <dd class="font-medium text-slate-800">{{ experience.provider?.user?.name ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-slate-500">Correo</dt>
                            <dd class="font-medium text-slate-800">{{ experience.provider?.user?.email ?? '—' }}</dd>
                        </div>
                    </dl>
                </section>

                <section class="rounded-xl bg-white p-6 shadow-sm">
                    <h3 class="mb-3 font-semibold text-slate-800">Acciones</h3>
                    <div class="space-y-2">
                        <button
                            class="w-full rounded-lg py-2.5 text-sm font-medium text-white"
                            :class="experience.is_active
                                ? 'bg-amber-600 hover:bg-amber-700'
                                : 'bg-emerald-600 hover:bg-emerald-700'"
                            @click="showToggle = true"
                        >
                            {{ experience.is_active ? 'Desactivar experiencia' : 'Activar experiencia' }}
                        </button>
                        <button
                            v-if="experience.status !== 'rejected'"
                            class="w-full rounded-lg border border-rose-200 py-2.5 text-sm font-medium text-rose-600 hover:bg-rose-50"
                            @click="showReject = true"
                        >
                            Rechazar experiencia
                        </button>
                    </div>
                    <p class="mt-3 text-xs text-slate-400">
                        Desactivar la oculta a los clientes sin eliminarla. Rechazar marca el estado
                        como rechazada y la desactiva.
                    </p>
                </section>
            </div>
        </div>

        <ConfirmModal
            :show="showToggle"
            :title="experience.is_active ? 'Desactivar experiencia' : 'Activar experiencia'"
            :message="experience.is_active
                ? 'Dejará de mostrarse a los clientes. ¿Confirmas?'
                : 'Volverá a estar disponible para los clientes. ¿Confirmas?'"
            :confirm-text="experience.is_active ? 'Desactivar' : 'Activar'"
            :confirm-color="experience.is_active ? 'danger' : 'success'"
            :processing="processing"
            @confirm="toggleActive"
            @cancel="showToggle = false"
        />
        <ConfirmModal
            :show="showReject"
            title="Rechazar experiencia"
            message="Se marcará como rechazada y se desactivará. ¿Confirmas?"
            confirm-text="Rechazar"
            confirm-color="danger"
            :processing="processing"
            @confirm="reject"
            @cancel="showReject = false"
        />
    </AdminLayout>
</template>
