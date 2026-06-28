<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_payouts', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_id')->constrained('providers')->cascadeOnDelete();

            $table->foreignId('provider_experience_schedule_id')
                ->constrained('provider_experience_schedules')
                ->cascadeOnDelete();

            $table->string('status')->default('not_ready');

            $table->timestamp('scheduled_release_at')->nullable();
            $table->timestamp('released_at')->nullable();

            $table->timestamp('held_at')->nullable();
            $table->string('hold_reason')->nullable();

            $table->foreignId('held_by_claim_id')
                ->nullable()
                ->constrained('booking_claims')
                ->nullOnDelete();

            $table->timestamp('released_from_hold_at')->nullable();

            // Snapshot financiero final.
            // Se llena solamente cuando el payout pasa a paid.
            $table->decimal('gross_amount', 12, 2)->nullable();
            $table->decimal('commission_rate', 5, 4)->nullable();
            $table->decimal('commission_amount', 12, 2)->nullable();
            $table->decimal('net_amount', 12, 2)->nullable();

            $table->string('currency', 3)->default('DOP');

            $table->string('payout_method')->nullable();
            $table->string('external_reference')->nullable();
            $table->text('failure_reason')->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique('provider_experience_schedule_id');
            $table->index(['provider_id', 'status']);
            $table->index(['status', 'scheduled_release_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_payouts');
    }
};