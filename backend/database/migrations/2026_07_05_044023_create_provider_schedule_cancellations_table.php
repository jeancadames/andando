<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_schedule_cancellations', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('provider_id');
            $table->unsignedBigInteger('provider_experience_id');
            $table->unsignedBigInteger('provider_experience_schedule_id');
            $table->unsignedBigInteger('cancelled_by_user_id')->nullable();

            $table->enum('reason_type', [
                'low_participants',
                'weather_or_natural_event',
                'provider_emergency',
                'operational_issue',
                'other',
            ]);

            $table->text('reason_description')->nullable();

            $table->unsignedInteger('bookings_cancelled_count')->default(0);

            $table->dateTime('scheduled_start_at')->nullable();
            $table->dateTime('policy_deadline_at')->nullable();

            $table->unsignedInteger('cancellation_penalty_hours')->nullable();

            $table->boolean('was_within_policy')->default(false);

            $table->timestamp('cancelled_at')->nullable();

            $table->timestamps();

            $table->foreign('provider_id', 'psc_provider_fk')
                ->references('id')
                ->on('providers')
                ->restrictOnDelete();

            $table->foreign('provider_experience_id', 'psc_experience_fk')
                ->references('id')
                ->on('provider_experiences')
                ->restrictOnDelete();

            $table->foreign('provider_experience_schedule_id', 'psc_schedule_fk')
                ->references('id')
                ->on('provider_experience_schedules')
                ->restrictOnDelete();

            $table->foreign('cancelled_by_user_id', 'psc_user_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->index(['provider_id', 'cancelled_at'], 'psc_provider_cancelled_idx');
            $table->index(['provider_id', 'reason_type'], 'psc_provider_reason_idx');
            $table->index(['provider_id', 'was_within_policy'], 'psc_provider_policy_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_schedule_cancellations');
    }
};