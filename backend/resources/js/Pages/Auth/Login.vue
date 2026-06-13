<script setup lang="ts">
import { useForm, Head } from '@inertiajs/vue3';

const form = useForm({
    email: '',
    password: '',
    remember: false,
});

function submit() {
    form.post('/admin/login', {
        onFinish: () => form.reset('password'),
    });
}
</script>

<template>
    <Head title="Acceso" />

    <div class="flex min-h-screen items-center justify-center bg-slate-100 p-4">
        <div class="w-full max-w-sm">
            <div class="mb-8 text-center">
                <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-sky-500 text-xl font-bold text-white">
                    A
                </div>
                <h1 class="text-xl font-semibold text-slate-900">Panel AndanDO</h1>
                <p class="text-sm text-slate-500">Acceso restringido</p>
            </div>

            <form class="rounded-2xl bg-white p-6 shadow-sm" @submit.prevent="submit">
                <div class="mb-4">
                    <label class="mb-1 block text-sm font-medium text-slate-700">Correo</label>
                    <input
                        v-model="form.email"
                        type="email"
                        autocomplete="username"
                        required
                        class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500"
                    />
                    <p v-if="form.errors.email" class="mt-1 text-xs text-rose-600">
                        {{ form.errors.email }}
                    </p>
                </div>

                <div class="mb-4">
                    <label class="mb-1 block text-sm font-medium text-slate-700">Contraseña</label>
                    <input
                        v-model="form.password"
                        type="password"
                        autocomplete="current-password"
                        required
                        class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-sky-500 focus:ring-sky-500"
                    />
                </div>

                <label class="mb-6 flex items-center gap-2 text-sm text-slate-600">
                    <input
                        v-model="form.remember"
                        type="checkbox"
                        class="rounded border-slate-300 text-sky-600 focus:ring-sky-500"
                    />
                    Mantener sesión iniciada
                </label>

                <button
                    type="submit"
                    :disabled="form.processing"
                    class="w-full rounded-lg bg-sky-600 py-2.5 text-sm font-medium text-white transition hover:bg-sky-700 disabled:opacity-50"
                >
                    {{ form.processing ? 'Verificando…' : 'Entrar' }}
                </button>
            </form>
        </div>
    </div>
</template>
