// Tipos que reflejan lo que envían los controladores Inertia.
// No son exhaustivos: cubren los campos usados en el panel.

export interface AdminUser {
    id: number;
    name: string;
    email: string;
    type: string;
}

export interface Flash {
    success: string | null;
    error: string | null;
}

export interface PageProps {
    auth: { user: AdminUser | null };
    flash: Flash;
    [key: string]: unknown;
}

// --- Paginación de Laravel (estilo length-aware) ---
export interface PaginationLink {
    url: string | null;
    label: string;
    active: boolean;
}

export interface Paginated<T> {
    data: T[];
    links: PaginationLink[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
    from: number | null;
    to: number | null;
}

// --- Entidades ---
export interface BusinessType {
    id: number;
    name: string;
    slug?: string;
}

export interface UserBasic {
    id: number;
    name: string;
    email?: string;
    phone?: string | null;
}

export interface Provider {
    id: number;
    user_id: number;
    business_name: string;
    rnc?: string;
    address?: string;
    city?: string;
    province?: string;
    status: 'pending' | 'approved' | 'rejected' | 'suspended';
    rejection_reason?: string | null;
    approved_at?: string | null;
    rejected_at?: string | null;
    user?: UserBasic;
    business_type?: BusinessType;
}

export interface ProviderDocument {
    id: number;
    type: string;
    status: string;
    disk: string;
    path: string;
    original_name: string;
    mime_type?: string | null;
    size_bytes: number;
    reviewed_at?: string | null;
}

export interface VerificationRequest {
    id: number;
    provider_id: number;
    status: 'pending' | 'approved' | 'rejected';
    submitted_at?: string | null;
    reviewed_at?: string | null;
    rejection_reason?: string | null;
    terms_accepted?: boolean;
    terms_accepted_at?: string | null;
    terms_version?: string | null;
    privacy_accepted?: boolean;
    privacy_accepted_at?: string | null;
    privacy_version?: string | null;
    created_at?: string;
    documents_count?: number;
    provider?: Provider;
    documents?: ProviderDocument[];
    reviewer?: UserBasic | null;
}

export interface Experience {
    id: number;
    provider_id: number;
    title: string;
    category?: string | null;
    description?: string | null;
    location?: string | null;
    province?: string | null;
    price: string | number;
    currency?: string;
    capacity: number;
    status: 'draft' | 'published' | 'paused' | 'rejected';
    is_active: boolean;
    published_at?: string | null;
    created_at?: string;
    provider?: Provider;
    bookings_count?: number;
    reviews_count?: number;
    photos?: ExperiencePhoto[];
    cover_photo?: ExperiencePhoto | null;
}

export interface ExperiencePhoto {
    id: number;
    path: string;
    is_cover: boolean;
    sort_order: number;
}

export interface BookingExperience {
    id: number;
    title: string;
    location?: string | null;
    province?: string | null;
}

export interface Booking {
    id: number;
    booking_code: string;
    booking_date: string;
    guests_count: number;
    total_amount: string | number;
    status: string;
    customer_name?: string | null;
    customer_email?: string | null;
    customer_phone?: string | null;
    experience?: BookingExperience;
    schedule?: { id: number; starts_at: string; ends_at?: string | null } | null;
}

export interface Claim {
    id: number;
    provider_booking_id: number;
    provider_id: number;
    user_id: number;
    reason: string;
    description: string;
    status: 'pending' | 'provider_replied' | 'resolved' | 'rejected';
    provider_response?: string | null;
    provider_replied_at?: string | null;
    resolved_at?: string | null;
    created_at?: string;
    provider?: Provider;
    user?: UserBasic;
    booking?: Booking;
}
