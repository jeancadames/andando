// Pequeñas utilidades de formato usadas en las páginas.

export function formatDate(value?: string | null): string {
    if (!value) return '—';
    const d = new Date(value);
    if (isNaN(d.getTime())) return '—';
    return d.toLocaleDateString('es-DO', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
    });
}

export function formatDateTime(value?: string | null): string {
    if (!value) return '—';
    const d = new Date(value);
    if (isNaN(d.getTime())) return '—';
    return d.toLocaleString('es-DO', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
}

export function formatMoney(value: string | number, currency = 'DOP'): string {
    const n = typeof value === 'string' ? parseFloat(value) : value;
    if (isNaN(n)) return '—';
    return new Intl.NumberFormat('es-DO', {
        style: 'currency',
        currency,
        minimumFractionDigits: 2,
    }).format(n);
}

export function formatBytes(bytes?: number): string {
    if (!bytes || bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    let i = 0;
    let n = bytes;
    while (n >= 1024 && i < units.length - 1) {
        n /= 1024;
        i++;
    }
    return `${n.toFixed(1)} ${units[i]}`;
}

const documentLabels: Record<string, string> = {
    identity_card: 'Cédula / Identidad',
    rnc_certificate: 'Certificado RNC',
    business_license: 'Licencia comercial',
    insurance_policy: 'Póliza de seguro / viaje',
};

export function documentLabel(type: string): string {
    return documentLabels[type] ?? type;
}

const claimReasonLabels: Record<string, string> = {
    // Ajusta según los valores reales que guarde tu app móvil.
    not_provided: 'Servicio no brindado',
    quality: 'Problema de calidad',
    refund: 'Solicitud de reembolso',
    other: 'Otro',
};

export function claimReasonLabel(reason: string): string {
    return claimReasonLabels[reason] ?? reason;
}
