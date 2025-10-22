import 'package:example/_code_builders/api_endpoint/annotations.dart';

part '_gen/api_example.gen.api_endpoint.dart';

// ============================================================================
// Example 1: Simple GET Request
// ============================================================================

class Post {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
}

@ApiEndpoint(
  method: HttpMethod.GET,
  path: '/posts/{id}',
  headers: {
    'Accept': Header(value: 'application/json', required: true),
  },
  pathParams: [
    PathParam(name: 'id', type: ParamType.integer, description: 'Post ID'),
  ],
  responseMapping: ResponseMapping(
    statusCode: 200,
    fields: {
      'id': FieldMapping(type: 'int'),
      'title': FieldMapping(type: 'String'),
      'content': FieldMapping(type: 'String'),
      'createdAt': FieldMapping(type: 'DateTime', jsonKey: 'created_at'),
    },
  ),
)
abstract class PostApi {
  Future<Post> getPost(int id);
}

// ============================================================================
// Example 2: POST with Request Body
// ============================================================================

class CreatePostRequest {
  final String title;
  final String content;
  final List<String> tags;

  CreatePostRequest({
    required this.title,
    required this.content,
    required this.tags,
  });
}

@ApiEndpoint(
  method: HttpMethod.POST,
  path: '/users/{userId}/posts',
  headers: {
    'Content-Type': Header(value: 'application/json', required: true),
    'Authorization': Header(value: 'Bearer {token}', required: true),
  },
  pathParams: [
    PathParam(name: 'userId', type: ParamType.integer),
  ],
  requestBody: const RequestBody(
    contentType: ContentType.json,
    fields: {
      'title': FieldMapping(type: 'String', required: true),
      'content': FieldMapping(type: 'String', required: true),
      'tags': FieldMapping(type: 'List<String>', required: false),
    },
  ),
  responseMapping: ResponseMapping(
    statusCode: 201,
    fields: {
      'id': FieldMapping(type: 'int', jsonKey: 'post_id'),
      'title': FieldMapping(type: 'String'),
      'content': FieldMapping(type: 'String'),
      'createdAt': FieldMapping(type: 'DateTime', jsonKey: 'created_at'),
    },
  ),
  auth: AuthConfig(
    type: AuthType.bearer,
    tokenField: 'token',
    headerName: 'Authorization',
  ),
  includeTimestamp: true,
)
abstract class CreatePostApi {
  Future<Post> createPost(int userId, CreatePostRequest request);
}

// ============================================================================
// Example 3: GET with Query Parameters
// ============================================================================

class PostList {
  final List<Post> posts;
  final int total;
  final int page;

  PostList({
    required this.posts,
    required this.total,
    required this.page,
  });
}

@ApiEndpoint(
  method: HttpMethod.GET,
  path: '/posts',
  headers: {
    'Accept': Header(value: 'application/json'),
  },
  queryParams: {
    'page': QueryParam(
      type: ParamType.integer,
      defaultValue: '1',
      description: 'Page number',
    ),
    'limit': QueryParam(
      type: ParamType.integer,
      defaultValue: '10',
      description: 'Items per page',
    ),
    'search': QueryParam(
      type: ParamType.string,
      required: false,
      description: 'Search term',
    ),
    'published': QueryParam(
      type: ParamType.boolean,
      required: false,
      description: 'Filter by published status',
    ),
  },
  responseMapping: ResponseMapping(
    statusCode: 200,
    fields: {
      'posts': FieldMapping(type: 'List<Post>'),
      'total': FieldMapping(type: 'int', jsonKey: 'total_count'),
      'page': FieldMapping(type: 'int', jsonKey: 'current_page'),
    },
  ),
)
abstract class PostListApi {
  Future<PostList> getPosts({
    int? page,
    int? limit,
    String? search,
    bool? published,
  });
}

// ============================================================================
// Example 4: Complex API with Multiple Features
// ============================================================================

class User {
  final int id;
  final String email;
  final String name;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.lastLogin,
  });
}

class UpdateUserRequest {
  final String? name;
  final String? email;
  final Map<String, dynamic>? settings;

  UpdateUserRequest({
    this.name,
    this.email,
    this.settings,
  });
}

@ApiEndpoint(
  method: HttpMethod.PATCH,
  path: '/users/{userId}',
  headers: {
    'Content-Type': Header(value: 'application/json', required: true),
    'Authorization': Header(value: 'Bearer {token}', required: true),
    'X-API-Key': Header(value: '{apiKey}', required: true, description: 'API Key'),
  },
  pathParams: [
    PathParam(
      name: 'userId',
      type: ParamType.integer,
      description: 'User ID to update',
    ),
  ],
  queryParams: {
    'notify': QueryParam(
      type: ParamType.boolean,
      defaultValue: 'true',
      description: 'Send notification email',
    ),
  },
  requestBody: RequestBody(
    contentType: ContentType.json,
    fields: {
      'name': FieldMapping(type: 'String?', required: false),
      'email': FieldMapping(type: 'String?', required: false, jsonKey: 'email_address'),
      'settings': FieldMapping(type: 'Map<String, dynamic>?', required: false),
    },
    description: 'User update payload',
  ),
  responseMapping: ResponseMapping(
    statusCode: 200,
    fields: {
      'id': FieldMapping(type: 'int', jsonKey: 'user_id'),
      'email': FieldMapping(type: 'String', jsonKey: 'email_address'),
      'name': FieldMapping(type: 'String', jsonKey: 'full_name'),
      'lastLogin': FieldMapping(type: 'DateTime', jsonKey: 'last_login_at'),
    },
    description: 'Updated user object',
  ),
  auth: AuthConfig(
    type: AuthType.bearer,
    tokenField: 'token',
  ),
  timeout: 5000,
  includeTimestamp: true,
)
abstract class UserApi {
  Future<User> updateUser(
    int userId,
    UpdateUserRequest request, {
    bool? notify,
    required String apiKey,
  });
}

// ============================================================================
// Main Function - Example Usage
// ============================================================================

void main() {
  print('API Endpoint Code Generator Example');
  print('====================================\n');

  print('This example showcases:');
  print('✓ Multiple enum types (HttpMethod, ContentType, AuthType, ParamType)');
  print('✓ Nested annotation classes (Header, QueryParam, PathParam, etc.)');
  print('✓ Strictly typed Map<String, T> fields');
  print('✓ List<T> fields with custom objects');
  print('✓ Complex nested structures');
  print('✓ DartObjectConverters for all types');
  print('\nRun `dart run build_runner build` to generate the API implementations!');
  print('\nGenerated classes will include:');
  print('- PostApiImpl');
  print('- CreatePostApiImpl');
  print('- PostListApiImpl');
  print('- UserApiImpl');
}
