<script setup lang="ts">
import { ref, watch } from 'vue';

const props = defineProps<{
    show: boolean;
    title: string;
    message?: string;
    confirmText?: string;
    confirmColor?: 'danger' | 'primary' | 'success';
    requireReason?: boolean;
    processing?: boolean;
}>();

const emit = defineEmits<{
    (e: 'confirm', reason: string): void;
    (e: 'cancel'): void;
}>();

const reason = ref('');

watch(
    () => props.show,
    (open) => {
        if (open) reason.value = '';
    },
);

const colorClasses: Record<string, string> = {
    danger: 'bg-rose-600 hover:bg-rose-700',
    primary: 'bg-sky-600 hover:bg-sky-700',
    success: 'bg-emerald-600 hover:bg-emerald-700',
};
</script>

<template>
    <Teleport to="body">
        <div
            v-if="show"
            class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4"
            @click.self="emit('cancel')"
        >
            <div class="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
                <h3 class="text-lg font-semibold text-slate-900">{{ title }}</h3>
                <p v-if="message" class="mt-2 text-sm text-slate-600">{{ message }}</p>

                <div v-if="requireReason" class="mt-4">
                    <label class="mb-1 block text-sm font-medium text-slate-700">
                        Motivo
                    </label>
                    <textarea
                        v-model="reason"
                        rows="3"
                        class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500"
                        placeholder="Explica el motivo…"
                    />
                </div>

                <div class="mt-6 flex justify-end gap-2">
                    <button
                        type="button"
                        class="rounded-lg px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100"
                        @click="emit('cancel')"
                    >
                        Cancelar
                    </button>
                    <button
                        type="button"
                        :disabled="processing || (requireReason && reason.trim().length < 5)"
                        class="rounded-lg px-4 py-2 text-sm font-medium text-white transition disabled:cursor-not-allowed disabled:opacity-50"
                        :class="colorClasses[confirmColor ?? 'primary']"
                        @click="emit('confirm', reason)"
                    >
                        {{ confirmText ?? 'Confirmar' }}
                    </button>
                </div>
            </div>
        </div>
    </Teleport>
</template>
