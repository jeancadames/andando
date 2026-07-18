<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('legal_documents', function (Blueprint $table) {
            $table->id();

            $table->string('type', 50);
            $table->string('audience', 30);
            $table->string('version', 30);

            $table->string('title');
            $table->longText('content');
            $table->text('summary')->nullable();
            $table->string('content_format', 20)->default('markdown');

            $table->timestamp('effective_at');
            $table->timestamp('published_at')->nullable();

            $table->boolean('requires_acceptance')->default(false);
            $table->string('change_level', 20)->default('minor');
            $table->boolean('is_active')->default(false);

            $table->char('checksum', 64);

            $table->foreignId('supersedes_id')
                ->nullable()
                ->constrained('legal_documents')
                ->nullOnDelete();

            $table->timestamps();

            $table->unique(
                ['type', 'audience', 'version'],
                'legal_documents_type_audience_version_unique'
            );

            $table->index(
                ['type', 'audience', 'is_active', 'effective_at'],
                'legal_documents_current_lookup_index'
            );

            $table->index('published_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('legal_documents');
    }
};