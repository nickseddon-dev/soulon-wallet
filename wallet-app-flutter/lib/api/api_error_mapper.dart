import 'dart:async';

enum ApiErrorKind { validation, unauthorized, forbidden, notFound, timeout, network, unknown }

class ApiClientException implements Exception {
  const ApiClientException({
    required this.kind,
    this.statusCode,
    this.code,
    this.message,
  });

  final ApiErrorKind kind;
  final int? statusCode;
  final String? code;
  final String? message;
}

String mapApiErrorMessage(Object error) {
  if (error is ApiClientException) {
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
    switch (error.kind) {
      case ApiErrorKind.validation:
        return '请求参数校验失败，请检查输入内容。';
      case ApiErrorKind.unauthorized:
        return '登录状态已失效，请重新认证后重试。';
      case ApiErrorKind.forbidden:
        return '当前账户无权限执行该操作。';
      case ApiErrorKind.notFound:
        return '请求资源不存在或已被移除。';
      case ApiErrorKind.timeout:
        return '链端响应超时，请稍后重试。';
      case ApiErrorKind.network:
        return '网络连接异常，请检查网络后重试。';
      case ApiErrorKind.unknown:
        return '链端服务暂不可用，请稍后重试。';
    }
  }
  if (error is TimeoutException) {
    return '链端响应超时，请稍后重试。';
  }
  if (error is FormatException) {
    return error.message;
  }
  if (error is StateError) {
    return error.message;
  }
  return '操作失败，请稍后重试。';
}
