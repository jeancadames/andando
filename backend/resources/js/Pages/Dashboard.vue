<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatusBadge from '@/Components/StatusBadge.vue';
import { formatDateTime } from '@/lib/format';
import type { VerificationRequest, Claim } from '@/types';

defineProps<{
    stats: {
        pendingRequests: number;
        approvedProviders: number;
        pendingClaims: number;
        activeExperiences: number;
        inactiveExperiences: number;
    };
    recentRequests: VerificationRequest[];
    recentClaims: Claim[];
}>();

const cards = [
    { key: 'pendingRequests', label: 'Solicitudes pendientes', href: '/admin/afiliados?status=pending', color: 'text-amber-600' },
    { key: 'approvedProviders', label: 'Afiliados aprobados', href: '/admin/afiliados?status=approved', color: 'text-emerald-600' },
    { key: 'pendingClaims', label: 'Reclamos abiertos', href: '/admin/reclamos', color: 'text-rose-600' },
    { key: 'activeExperiences', label: 'Experiencias activas', href: '/admin/experiencias?active=active', color: 'text-sky-600' },
] as const;
</script>

<template>
    <Head title="Dashboard" />
    <AdminLayout>
        <template #title>Dashboard</template>

        <!-- Métricas -->
        <div class="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <Link
                v-for="card in cards"
                :key="card.key"
                :href="card.href"
                class="rounded-xl bg-white p-5 shadow-sm transition hover:shadow-md"
            >
                <p class="text-sm text-slate-500">{{ card.label }}</p>
                <p class="mt-2 text-3xl font-semibold" :class="card.color">
                    {{ stats[card.key] }}
                </p>
            </Link>
        </div>

        <div class="mt-8 grid gap-6 lg:grid-cols-2">
            <!-- Solicitudes recientes -->
            <section class="rounded-xl bg-white shadow-sm">
                <div class="flex items-center justify-between border-b border-slate-100 px-5 py-4">
                    <h2 class="font-semibold text-slate-800">Solicitudes pendientes</h2>
                    <Link href="/admin/afiliados" class="text-sm text-sky-600 hover:underline">
                        Ver todas
                    </Link>
                </div>
                <ul v-if="recentRequests.length" class="divide-y divide-slate-100">
                    <li v-for="req in recentRequests" :key="req.id">
                        <Link
                            :href="`/admin/afiliados/${req.id}`"
                            class="flex items-center justify-between px-5 py-3 hover:bg-slate-50"
                        >
                            <div>
                                <p class="font-medium text-slate-800">
                                    {{ req.provider?.business_name ?? 'Sin nombre' }}
                                </p>
                                <p class="text-xs text-slate-500">
                                    {{ req.provider?.business_type?.name }} ·
                                    {{ formatDateTime(req.submitted_at) }}
                                </p>
                            </div>
                            <StatusBadge :status="req.status" />
                        </Link>
                    </li>
                </ul>
                <p v-else class="px-5 py-8 text-center text-sm text-slate-400">
                    No hay solicitudes pendientes.
                </p>
            </section>

            <!-- Reclamos recientes -->
            <section class="rounded-xl bg-white shadow-sm">
                <div class="flex items-center justify-between border-b border-slate-100 px-5 py-4">
                    <h2 class="font-semibold text-slate-800">Reclamos abiertos</h2>
                    <Link href="/admin/reclamos" class="text-sm text-sky-600 hover:underline">
                        Ver todos
                    </Link>
                </div>
                <ul v-if="recentClaims.length" class="divide-y divide-slate-100">
                    <li v-for="claim in recentClaims" :key="claim.id">
                        <Link
                            :href="`/admin/reclamos/${claim.id}`"
                            class="flex items-center justify-between px-5 py-3 hover:bg-slate-50"
                        >
                            <div>
                                <p class="font-medium text-slate-800">{{ claim.reason }}</p>
                                <p class="text-xs text-slate-500">
                                    {{ claim.provider?.business_name }} · {{ claim.user?.name }}
                                </p>
                            </div>
                            <StatusBadge :status="claim.status" />
                        </Link>
                    </li>
                </ul>
                <p v-else class="px-5 py-8 text-center text-sm text-slate-400">
                    No hay reclamos abiertos.
                </p>
            </section>
        </div>
    </AdminLayout>
</template>
