/// HTTP methods supported by the API endpoint
enum HttpMethod {
  GET,
  POST,
  PUT,
  PATCH,
  DELETE,
}

/// Content types for request/response bodies
enum ContentType {
  json,
  formUrlEncoded,
  multipart,
  text,
}

/// Authentication types
enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
}

/// Parameter types for path and query parameters
enum ParamType {
  string,
  integer,
  boolean,
  double,
}

/// Represents an HTTP header
class Header {
  final String value;
  final bool required;
  final String? description;

  const Header({
    required this.value,
    this.required = true,
    this.description,
  });

  @override
  String toString() => 'Header(value: $value, required: $required, description: $description)';
}

/// Represents a query parameter
class QueryParam {
  final ParamType type;
  final String? defaultValue;
  final bool required;
  final String? description;

  const QueryParam({
    required this.type,
    this.defaultValue,
    this.required = false,
    this.description,
  });

  @override
  String toString() => 'QueryParam(type: $type, defaultValue: $defaultValue, required: $required)';
}

/// Represents a path parameter
class PathParam {
  final String name;
  final ParamType type;
  final String? description;

  const PathParam({
    required this.name,
    required this.type,
    this.description,
  });

  @override
  String toString() => 'PathParam(name: $name, type: $type, description: $description)';
}

/// Represents a field mapping for request/response bodies
class FieldMapping {
  final String type;
  final bool required;
  final String? jsonKey;
  final String? defaultValue;

  const FieldMapping({
    required this.type,
    this.required = true,
    this.jsonKey,
    this.defaultValue,
  });

  @override
  String toString() => 'FieldMapping(type: $type, required: $required, jsonKey: $jsonKey)';
}

/// Represents the request body configuration
class RequestBody {
  final ContentType contentType;
  final Map<String, FieldMapping> fields;
  final String? description;

  const RequestBody({
    required this.contentType,
    required this.fields,
    this.description,
  });

  @override
  String toString() => 'RequestBody(contentType: $contentType, fields: $fields)';
}

/// Represents the response mapping configuration
class ResponseMapping {
  final int statusCode;
  final Map<String, FieldMapping> fields;
  final String? description;

  const ResponseMapping({
    required this.statusCode,
    required this.fields,
    this.description,
  });

  @override
  String toString() => 'ResponseMapping(statusCode: $statusCode, fields: $fields)';
}

/// Authentication configuration
class AuthConfig {
  final AuthType type;
  final String? tokenField;
  final String? headerName;
  final String? queryParamName;

  const AuthConfig({
    required this.type,
    this.tokenField,
    this.headerName,
    this.queryParamName,
  });

  @override
  String toString() => 'AuthConfig(type: $type, tokenField: $tokenField, headerName: $headerName)';
}

/// Main annotation for API endpoints
class ApiEndpoint {
  final HttpMethod method;
  final String path;
  final Map<String, Header> headers;
  final List<PathParam> pathParams;
  final Map<String, QueryParam> queryParams;
  final RequestBody? requestBody;
  final ResponseMapping responseMapping;
  final AuthConfig? auth;
  final int? timeout;
  final bool includeTimestamp;

  const ApiEndpoint({
    required this.method,
    required this.path,
    this.headers = const {},
    this.pathParams = const [],
    this.queryParams = const {},
    this.requestBody,
    required this.responseMapping,
    this.auth,
    this.timeout,
    this.includeTimestamp = false,
  });

  @override
  String toString() {
    return 'ApiEndpoint(method: $method, path: $path, headers: $headers, pathParams: $pathParams, queryParams: $queryParams)';
  }
}
