<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id'    => User::factory(),
            'title'      => $this->faker->words(4, true),
            'body'       => $this->faker->paragraph(),
            'created_at' => $this->faker->dateTimeBetween('-3 months', now()),
            'updated_at' => now(),
        ];
    }
}
