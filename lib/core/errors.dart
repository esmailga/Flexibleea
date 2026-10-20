import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase exceptions into messages that make sense to end users.
String describeError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this project.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
    }
    return error.message ?? 'Authentication failed. Please try again.';
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'The service is unavailable. Check your connection.';
      case 'not-found':
      case 'object-not-found':
        return 'That item no longer exists.';
      case 'canceled':
        return 'The upload was cancelled.';
    }
    return error.message ?? 'Something went wrong. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
