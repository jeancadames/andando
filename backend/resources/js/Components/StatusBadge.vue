<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    status: string;
}>();

// Mapa de estado -> { texto, clases }
const map: Record<string, { label: string; classes: string }> = {
    // Solicitudes / proveedores
    pending: { label: 'Pendiente', classes: 'bg-amber-100 text-amber-800' },
    approved: { label: 'Aprobado', classes: 'bg-emerald-100 text-emerald-800' },
    rejected: { label: 'Rechazado', classes: 'bg-rose-100 text-rose-800' },
    suspended: { label: 'Suspendido', classes: 'bg-slate-200 text-slate-700' },

    // Reclamos
    provider_replied: { label: 'Respondido', classes: 'bg-sky-100 text-sky-800' },
    resolved: { label: 'Resuelto', classes: 'bg-emerald-100 text-emerald-800' },

    // Experiencias
    draft: { label: 'Borrador', classes: 'bg-slate-200 text-slate-700' },
    published: { label: 'Publicada', classes: 'bg-emerald-100 text-emerald-800' },
    paused: { label: 'Pausada', classes: 'bg-amber-100 text-amber-800' },

    // AndanDO Admin Payments UI
    scheduled: { label: 'Programado', classes: 'bg-amber-100 text-amber-800' },
    processing: { label: 'Procesando', classes: 'bg-sky-100 text-sky-800' },
    pending_verification: { label: 'Requiere verificación', classes: 'bg-violet-100 text-violet-800' },
    paid: { label: 'Pagado', classes: 'bg-emerald-100 text-emerald-800' },
    failed: { label: 'Fallido', classes: 'bg-rose-100 text-rose-800' },
    cancelled: { label: 'Cancelado', classes: 'bg-slate-200 text-slate-700' },
    refunded: { label: 'Reembolsado', classes: 'bg-indigo-100 text-indigo-800' },
    partially_refunded: { label: 'Reembolso parcial', classes: 'bg-fuchsia-100 text-fuchsia-800' },
    succeeded: { label: 'Completado', classes: 'bg-emerald-100 text-emerald-800' },

    // Documentos
    active: { label: 'Activo', classes: 'bg-emerald-100 text-emerald-800' },
};

const resolved = computed(
    () => map[props.status] ?? { label: props.status, classes: 'bg-slate-200 text-slate-700' },
);
</script>

<template>
    <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
        :class="resolved.classes"
    >
        {{ resolved.label }}
    </span>
</template>
