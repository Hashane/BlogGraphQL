<?php declare(strict_types=1);

namespace App\GraphQL\Queries;

use App\Models\Post;
use Illuminate\Support\Facades\Log;

final readonly class PostResolver
{
    /** @param  array{}  $args */
    public function __invoke(null $_, array $args)
    {
        $post = Post::where('id', $args['id'])->firstOrFail();
        Log::info('post created.');
        return $post;
    }
}
