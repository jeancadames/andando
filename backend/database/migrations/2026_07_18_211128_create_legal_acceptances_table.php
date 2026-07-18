<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('legal_acceptances', function (Blueprint $table) {
            $table->id();

            $table->foreignId('legal_document_id')
                ->constrained('legal_documents')
                ->cascadeOnDelete();

            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('provider_id')
                ->nullable()
                ->constrained('providers')
                ->cascadeOnDelete();

            $table->foreignId('booking_id')
                ->nullable()
                ->constrained('provider_bookings')
                ->nullOnDelete();

            $table->foreignId('experience_id')
                ->nullable()
                ->constrained('provider_experiences')
                ->nullOnDelete();

            $table->foreignId('schedule_id')
                ->nullable()
                ->constrained('provider_experience_schedules')
                ->nullOnDelete();

            $table->timestamp('accepted_at');

            $table->char('document_checksum', 64);

            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('platform', 30)->nullable();
            $table->string('app_version', 30)->nullable();
            $table->string('locale', 10)->default('es');

            $table->json('metadata')->nullable();

            $table->timestamps();

            $table->index(
                ['user_id', 'legal_document_id', 'accepted_at'],
                'legal_acceptances_user_document_index'
            );

            $table->index(
                ['provider_id', 'legal_document_id', 'accepted_at'],
                'legal_acceptances_provider_document_index'
            );

            $table->index(
                ['booking_id', 'legal_document_id'],
                'legal_acceptances_booking_document_index'
            );

            $table->index('accepted_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('legal_acceptances');
    }
};