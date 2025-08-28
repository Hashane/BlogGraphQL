<?php declare(strict_types=1);

namespace App\GraphQL\Queries;

use App\Models\Post;

final readonly class PostsResolver
{
    /** @param  array{}  $args */
    public function __invoke(null $_, array $args)
    {
        return Post::latest()->get();
    }
}
