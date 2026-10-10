import 'package:dio/dio.dart';

class AppError {
  final String code;
  final String message;
  final dynamic details;
  final String userFriendlyMessage;

  const AppError({
    required this.code,
    required this.message,
    this.details,
    required this.userFriendlyMessage,
  });

  factory AppError.fromDynamic(dynamic error) {
    if (error is DioException) {
      return AppError.fromDioException(error);
    }
    if (error is ArgumentError) {
      return AppError(
        code: 'ARGUMENT_ERROR',
        message: error.message?.toString() ?? 'Invalid argument',
        userFriendlyMessage: error.message?.toString() ?? 'Please review your input.',
      );
    }
    if (error is StateError) {
      return AppError(
        code: 'STATE_ERROR',
        message: error.message,
        userFriendlyMessage: error.message,
      );
    }
    return AppError(
      code: 'UNKNOWN_ERROR',
      message: error?.toString() ?? 'An unexpected error occurred',
      userFriendlyMessage: 'Something went wrong. Please try again.',
    );
  }

  factory AppError.fromDioException(DioException exception) {
    // 1. Check if backend returned structured error {"error": {"code", "message", "details"}}
    final responseData = exception.response?.data;
    if (responseData is Map<String, dynamic>) {
      final errObj = responseData['error'];
      if (errObj is Map<String, dynamic>) {
        final code = errObj['code']?.toString() ?? 'SERVER_ERROR';
        final message = errObj['message']?.toString() ?? 'Server error';
        final details = errObj['details'];

        return AppError(
          code: code,
          message: message,
          details: details,
          userFriendlyMessage: _mapCodeToFriendlyMessage(code, message, details),
        );
      } else if (responseData.containsKey('detail')) {
        final detailMsg = responseData['detail'].toString();
        return AppError(
          code: 'BACKEND_DETAIL',
          message: detailMsg,
          userFriendlyMessage: detailMsg,
        );
      }
    }

    // 2. Handle HTTP Status codes
    final statusCode = exception.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return const AppError(
            code: 'BAD_REQUEST',
            message: 'Invalid request data',
            userFriendlyMessage: 'Invalid details provided. Please check all fields.',
          );
        case 401:
          return const AppError(
            code: 'UNAUTHORIZED',
            message: 'Authentication token missing or invalid',
            userFriendlyMessage: 'Your session has expired. Please sign in again.',
          );
        case 403:
          return const AppError(
            code: 'FORBIDDEN',
            message: 'Access forbidden for current user role',
            userFriendlyMessage: 'You do not have authorization to perform this operation.',
          );
        case 404:
          return const AppError(
            code: 'NOT_FOUND',
            message: 'Resource not found',
            userFriendlyMessage: 'The requested record could not be found.',
          );
        case 409:
          return const AppError(
            code: 'CONFLICT',
            message: 'Resource conflict or duplicate entry',
            userFriendlyMessage: 'This record already exists or has been modified elsewhere.',
          );
        case 422:
          return const AppError(
            code: 'UNPROCESSABLE_ENTITY',
            message: 'Validation failed on server',
            userFriendlyMessage: 'Please ensure all required fields and attachments are complete.',
          );
        case 500:
        case 502:
        case 503:
          return const AppError(
            code: 'SERVER_ERROR',
            message: 'SolarPro server error',
            userFriendlyMessage: 'SolarPro server is momentarily busy. Please try again shortly.',
          );
      }
    }

    // 3. Handle Network connectivity timeouts
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppError(
          code: 'NETWORK_TIMEOUT',
          message: 'Connection timed out',
          userFriendlyMessage: 'Connection timed out. Action queued for sync once back online.',
        );
      case DioExceptionType.connectionError:
        return const AppError(
          code: 'NO_INTERNET',
          message: 'Could not connect to SolarPro server',
          userFriendlyMessage: 'Offline: Changes saved locally and will sync automatically.',
        );
      default:
        return AppError(
          code: 'NETWORK_ERROR',
          message: exception.message ?? 'Network communication failure',
          userFriendlyMessage: 'Network issue. Please check your internet connection.',
        );
    }
  }

  static String _mapCodeToFriendlyMessage(String code, String defaultMessage, dynamic details) {
    switch (code.toUpperCase()) {
      case 'PHOTO_REQUIRED':
      case 'PHOTO_PROOF_REQUIRED':
        return 'At least one photo proof is required before completing this assignment.';
      case 'RESOLUTION_NOTE_REQUIRED':
        return 'A detailed resolution note is strictly required before closing this ticket.';
      case 'PAYMENT_PLAN_LOCKED':
        return 'This payment plan is locked because collections have already begun.';
      case 'PLAN_PERCENTAGE_INVALID':
        return 'Payment plan installments must total exactly 100%.';
      case 'UNAUTHORIZED':
      case 'TOKEN_EXPIRED':
        return 'Your session has expired. Please log in again.';
      case 'EMAIL_NOT_VERIFIED':
        return 'Email verification is required before logging in.';
      case 'INVALID_STAGE_TRANSITION':
        return 'Customer is not in the required workflow stage for this action.';
      case 'OVERDUE_DEMAND':
        return 'Cannot proceed: This customer has pending overdue discom demands.';
      case 'SERIAL_NOT_FOUND':
        return 'Serial number not found in equipment registry. Please check barcode.';
      case 'FILE_TOO_LARGE':
        return 'Selected file exceeds maximum upload size (10 MB).';
      case 'INVALID_FILE_TYPE':
        return 'Only JPG, PNG, and PDF files are accepted.';
      default:
        return defaultMessage.isNotEmpty ? defaultMessage : 'Action could not be completed.';
    }
  }

  @override
  String toString() => 'AppError(code: $code, message: $message, friendly: $userFriendlyMessage)';
}
