part of 'builder.dart';

final _dartObjectConverters = {
  HttpMethod: _httpMethodConverter,
  ContentType: _contentTypeConverter,
  AuthType: _authTypeConverter,
  ParamType: _paramTypeConverter,
  Header: _headerConverter,
  QueryParam: _queryParamConverter,
  PathParam: _pathParamConverter,
  FieldMapping: _fieldMappingConverter,
  RequestBody: _requestBodyConverter,
  ResponseMapping: _responseMappingConverter,
  AuthConfig: _authConfigConverter,
  ApiEndpoint: _apiEndpointConverter,
};

// Enum converters
DartObjectConverter<HttpMethod> _httpMethodConverter = DartObjectConverter<HttpMethod>(
  (dartObject) => HttpMethod.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<ContentType> _contentTypeConverter = DartObjectConverter<ContentType>(
  (dartObject) => ContentType.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<AuthType> _authTypeConverter = DartObjectConverter<AuthType>(
  (dartObject) => AuthType.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<ParamType> _paramTypeConverter = DartObjectConverter<ParamType>(
  (dartObject) => ParamType.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

// Simple class converters
DartObjectConverter<Header> _headerConverter = DartObjectConverter<Header>(
  (dartObject) => Header(
    value: dartObject.getFieldValue('value') as String,
    required: dartObject.getFieldValue('required') as bool,
    description: dartObject.getFieldValue('description') as String?,
  ),
);

DartObjectConverter<QueryParam> _queryParamConverter = DartObjectConverter<QueryParam>(
  (dartObject) => QueryParam(
    type: dartObject.getFieldValue('type', [_paramTypeConverter]) as ParamType,
    defaultValue: dartObject.getFieldValue('defaultValue') as String?,
    required: dartObject.getFieldValue('required') as bool,
    description: dartObject.getFieldValue('description') as String?,
  ),
);

DartObjectConverter<PathParam> _pathParamConverter = DartObjectConverter<PathParam>(
  (dartObject) => PathParam(
    name: dartObject.getFieldValue('name') as String,
    type: dartObject.getFieldValue('type', [_paramTypeConverter]) as ParamType,
    description: dartObject.getFieldValue('description') as String?,
  ),
);

DartObjectConverter<FieldMapping> _fieldMappingConverter = DartObjectConverter<FieldMapping>(
  (dartObject) => FieldMapping(
    type: dartObject.getFieldValue('type') as String,
    required: dartObject.getFieldValue('required') as bool,
    jsonKey: dartObject.getFieldValue('jsonKey') as String?,
    defaultValue: dartObject.getFieldValue('defaultValue') as String?,
  ),
);

// Complex class converters with Map<String, T>
DartObjectConverter<RequestBody> _requestBodyConverter = DartObjectConverter<RequestBody>(
  (dartObject) => RequestBody(
    contentType: dartObject.getFieldValue('contentType', [_contentTypeConverter]) as ContentType,
    fields: (dartObject.getFieldValue('fields', [_fieldMappingConverter]) as Map).cast<String, FieldMapping>(),
    description: dartObject.getFieldValue('description') as String?,
  ),
);

DartObjectConverter<ResponseMapping> _responseMappingConverter = DartObjectConverter<ResponseMapping>(
  (dartObject) => ResponseMapping(
    statusCode: dartObject.getFieldValue('statusCode') as int,
    fields: (dartObject.getFieldValue('fields', [_fieldMappingConverter]) as Map).cast<String, FieldMapping>(),
    description: dartObject.getFieldValue('description') as String?,
  ),
);

DartObjectConverter<AuthConfig> _authConfigConverter = DartObjectConverter<AuthConfig>(
  (dartObject) => AuthConfig(
    type: dartObject.getFieldValue('type', [_authTypeConverter]) as AuthType,
    tokenField: dartObject.getFieldValue('tokenField') as String?,
    headerName: dartObject.getFieldValue('headerName') as String?,
    queryParamName: dartObject.getFieldValue('queryParamName') as String?,
  ),
);

// Main annotation converter with all nested types
DartObjectConverter<ApiEndpoint> _apiEndpointConverter = DartObjectConverter<ApiEndpoint>(
  (dartObject) => ApiEndpoint(
    method: dartObject.getFieldValue('method', [_httpMethodConverter]) as HttpMethod,
    path: dartObject.getFieldValue('path') as String,
    headers: (dartObject.getFieldValue('headers', [_headerConverter]) as Map).cast<String, Header>(),
    pathParams: dartObject.getFieldValue('pathParams', [_pathParamConverter]).cast<PathParam>(),
    queryParams: (dartObject.getFieldValue('queryParams', [_queryParamConverter]) as Map).cast<String, QueryParam>(),
    requestBody: dartObject.getFieldValue('requestBody', [_requestBodyConverter]) as RequestBody?,
    responseMapping: dartObject.getFieldValue('responseMapping', [_responseMappingConverter]) as ResponseMapping,
    auth: dartObject.getFieldValue('auth', [_authConfigConverter]) as AuthConfig?,
    timeout: dartObject.getFieldValue('timeout') as int?,
    includeTimestamp: dartObject.getFieldValue('includeTimestamp') as bool,
  ),
);
