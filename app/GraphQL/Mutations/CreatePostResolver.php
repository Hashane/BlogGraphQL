<?php declare(strict_types=1);

namespace App\GraphQL\Mutations;

use App\Models\Post;

final readonly class CreatePostResolver
{
    /** @param  array{}  $args */
    public function __invoke(null $_, array $args)
    {
        return Post::create(['id' => $args['id'], 'title' => $args['title'], 'body' => $args['body'] ]);
    }
}
