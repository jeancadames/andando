<?php

namespace App\Enums;

enum ExperienceDifficulty: string
{
    case Easy = 'easy';
    case Moderate = 'moderate';
    case Hard = 'hard';

    public function label(): string
    {
        return match ($this) {
            self::Easy => 'Fácil',
            self::Moderate => 'Moderada',
            self::Hard => 'Difícil',
        };
    }

    public static function values(): array
    {
        return array_map(
            static fn (self $difficulty): string => $difficulty->value,
            self::cases(),
        );
    }
}
